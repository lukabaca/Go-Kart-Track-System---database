use carttrackdb;

drop procedure if exists insertUserAndRolesIds;
DELIMITER //
create procedure insertUserAndRolesIds (in user_id int, in role_id int)
begin 
	insert into user_roles(user_id, role_id) values(user_id, role_id);
end //

drop procedure if exists getUserByUserEmail;
DELIMITER //
create procedure getUserByUserEmail (in email varchar(45))
begin 
	select * from user where user.email = email;
end //

drop procedure if exists getUserRolesByUserID;
DELIMITER //
create procedure getUserRolesByUserID (in user_id int)
begin 
	select role.name from user join user_roles on user.id = user_roles.user_ID join role on user_roles.role_ID = role.id
	where user.id = user_id;
end //

drop procedure if exists getUserRecordings;
DELIMITER //
create procedure getUserRecordings (in user_id int)
begin 
	select * from recording where recording.user_id = user_id;
end //

drop procedure if exists getUserReservations;
DELIMITER //
create procedure getUserReservations (in user_id int)
begin 
	select * from reservation where reservation.user_id = user_id;
end //

drop procedure if exists getTimeTypeReservations;
DELIMITER //
create procedure getTimeTypeReservations ()
begin 
	select * from reservation where by_time_reservation_type = 1;
end //

drop procedure if exists getRecords;
DELIMITER //
create procedure getRecords (in recordLimit int, in timeMode int)
/*
1 - records allTime, 2 - month record, 3 - week record
*/
begin 
	declare actualDate date;
    select curdate() into actualDate;
	CASE timeMode
    WHEN 1 THEN 
		select * from lap order by minute asc, second asc, milisecond asc limit recordLimit;
    WHEN 2 THEN 
		select * from lap 
        where ((select month(actualDate)) -  (select month(lap.date)) = 1) 
		order by minute asc, second asc, milisecond asc limit 10;
    WHEN 3 THEN 
		select * from lap
        where (datediff(actualDate, date) between 0 and 7) 
		order by minute asc, second asc, milisecond asc limit 10;
    ELSE select * from lap join user on lap.user_ID = user.id join kart on lap.kart_ID = kart.ID order by minute asc, second asc, milisecond asc 
    limit recordLimit;
	END case;
    
end //

drop procedure if exists getTimePerOneRide;
DELIMITER //
create procedure getTimePerOneRide ()
begin 
	select * from ride_time_dictionary where ride_count = 1;
end //

drop procedure if exists isReservationValid;
DELIMITER //
create procedure isReservationValid(in user_id int, in startDate datetime, in endDate datetime, in byTimeReservationType tinyint)
begin 
	declare rowsReturned int;
    declare trackOpeningTime time;
    declare trackEndTime time;
    select hour_start into trackOpeningTime from trackinfo;
    select hour_end into trackEndTime from trackinfo;

	if byTimeReservationType = 0 then
		if (cast(startDate as time) < cast(trackOpeningTime as time) or cast(endDate as time) > cast(trackEndTime as time)) then
			select 3;
		end if;
	end if;
    
	if startDate < (select now()) then
		select 2;
	else
		select count(*) into rowsReturned from reservation where
		(startDate >= reservation.start_date and endDate <= reservation.end_date)
		or (startDate < reservation.start_date and endDate > reservation.start_date and endDate <= reservation.end_date)
		or (endDate > reservation.end_date and startDate >= reservation.start_date and startDate < reservation.end_date)
		or (startDate < reservation.start_date and endDate > reservation.end_date);
		if rowsReturned = 0 then
			select 1;
		else 
			select 0;
		end if;
    end if;
end //

drop procedure if exists getKartPrizeByNumberOfRides;
DELIMITER //
create procedure getKartPrizeByNumberOfRides(in kart_id int, in numberOfRides int)
begin 
	declare kartPrize int;
	declare totalKartPrize int;
	if numberOfRides > 0 then
		select prize into kartPrize from kart where kart.id = kart_id;
		set totalKartPrize = kartPrize * numberOfRides;
    else 
		set totalKartPrize = -1;
    end if;
    select totalKartPrize;
end //

drop procedure if exists getKartsInReservation;
DELIMITER //
create procedure getKartsInReservation(in reservation_id int)
begin 
	select kart.id, kart.name, kart.prize, kart.availability from reservation join reservation_kart on reservation.id = reservation_kart.reservation_id 
    join kart on kart.id = reservation_kart.kart_id 
    where reservation.id = reservation_id;
end //

drop procedure if exists getReservationsForViewType;
DELIMITER //
create procedure getReservationsForViewType(in reservation_date date, in viewType int)
begin 
	declare reservation_date_day date;
    select date_format(reservation_date, '%Y%m%d') into reservation_date_day;
/*
1 - day view, 2 - week view, 3 - month view
*/
	CASE viewType
    WHEN 1 THEN 
		select * from reservation where reservation_date_day = (select date_format(reservation.start_date, '%Y%m%d'));
    WHEN 2 THEN 
		select * from reservation where reservation.start_date between reservation_date_day and date_add(reservation_date_day, interval 7 day);
    WHEN 3 THEN 
		select * from reservation where (select date_format(reservation.start_date, '%m')) = (select date_format(reservation_date_day, '%m'));
    ELSE select * from reservation where reservation.start_date = reservation_date_day + interval 7 day;
	END case;
end //

drop procedure if exists getReservations;
DELIMITER //
create procedure getReservations(in recordStart int, in length int, in columnName varchar(255), in orderDir varchar(4), in searchValue varchar(255))
begin 
	declare colStartDate varchar(50) default 'reservation.start_date';
    declare colEndDate varchar(50) default 'reservation.end_date';
    declare colCost varchar(50) default 'reservation.cost';
    declare reservationType varchar(50) default 'reservation.by_time_reservation_type';
    declare reservationOwnerName varchar(50) default 'user.name';
    declare reservationOwnerSurname varchar(50) default 'user.surname';
    set @SQLStatement = 'select reservation.id as ''id'', reservation.start_date, reservation.end_date,
    reservation.cost, reservation.by_time_reservation_type, user.id as ''user_id'', user.name, user.surname 
    from reservation join user where
    reservation.user_id = user.id ';
    if searchValue != '' then
		set @SQLStatement = concat(@SQLStatement, 'and (', colStartDate, ' like("%', searchValue, '%")', ' OR');
		set @SQLStatement = concat(@SQLStatement, ' ', colEndDate, ' like("%', searchValue, '%")', ' OR');
		set @SQLStatement = concat(@SQLStatement, ' ', colCost, ' like("%', searchValue, '%")', ' OR');
        set @SQLStatement = concat(@SQLStatement, ' ', reservationType, ' like("%', searchValue, '%")', ' OR');
        set @SQLStatement = concat(@SQLStatement, ' ', reservationOwnerName, ' like("%', searchValue, '%")', ' OR');
        set @SQLStatement = concat(@SQLStatement, ' ', reservationOwnerSurname, ' like("%', searchValue, '%"))');
    end if;
    set @SQLStatement = concat(@SQLStatement, ' ', 'order by', ' ', columnName);
	set @SQLStatement = concat(@SQLStatement, ' ', orderDir);
	set @SQLStatement = concat(@SQLStatement, ' ', 'limit', ' ', length);
	set @SQLStatement = concat(@SQLStatement, ' ', 'offset', ' ', recordStart);
    prepare stmt from @SQLStatement;
    execute stmt;
end //

drop procedure if exists getKarts;
DELIMITER //
create procedure getKarts(in recordStart int, in length int, in columnName varchar(255), in orderDir varchar(4), in searchValue varchar(255))
begin 
	declare colName varchar(20) default 'name';
    declare colPrize varchar(20) default 'prize';
    set @SQLStatement = 'select * from kart ';
    if searchValue != '' then
		set @SQLStatement = concat(@SQLStatement, 'where ', colname, ' like("%', searchValue, '%")', ' OR');
		set @SQLStatement = concat(@SQLStatement, ' ', colPrize, ' like("%', searchValue, '%")');
    end if;
    set @SQLStatement = concat(@SQLStatement, ' ', 'order by', ' ', columnName);
	set @SQLStatement = concat(@SQLStatement, ' ', orderDir);
	set @SQLStatement = concat(@SQLStatement, ' ', 'limit', ' ', length);
	set @SQLStatement = concat(@SQLStatement, ' ', 'offset', ' ', recordStart);
    prepare stmt from @SQLStatement;
    execute stmt;
end //

drop procedure if exists getLapSessions;
DELIMITER //
create procedure getLapSessions(in recordStart int, in length int, in columnName varchar(255), in orderDir varchar(4), in searchValue varchar(255), in userId int)
begin 
	declare colStartDate varchar(20) default 'start_date';
    declare colEndDate varchar(20) default 'end_date';
    set @SQLStatement = 'select * from lap_session';
    set @SQLStatement = concat(@SQLStatement, ' ', 'where lap_session.user_id=', ' ', userId);
    if searchValue != '' then
		set @SQLStatement = concat(@SQLStatement, ' and (', colStartDate, ' like("%', searchValue, '%")', ' OR');
		set @SQLStatement = concat(@SQLStatement, ' ', colEndDate, ' like("%', searchValue, '%"))');
    end if;
    set @SQLStatement = concat(@SQLStatement, ' ', 'order by', ' ', columnName);
	set @SQLStatement = concat(@SQLStatement, ' ', orderDir);
	set @SQLStatement = concat(@SQLStatement, ' ', 'limit', ' ', length);
	set @SQLStatement = concat(@SQLStatement, ' ', 'offset', ' ', recordStart);
    prepare stmt from @SQLStatement;
    execute stmt;
end //

drop procedure if exists getUsers;
DELIMITER //
create procedure getUsers(in recordStart int, in length int, in columnName varchar(255), in orderDir varchar(4), in searchValue varchar(255))
begin 
	declare colName varchar(20) default 'user.name';
    declare colSurname varchar(20) default 'user.surname';
    declare colBirthDate varchar(20) default 'user.birth_date';
    declare colPesel varchar(20) default 'user.pesel';
    declare colDocumentId varchar(20) default 'user.document_id';
    declare colEmail varchar(20) default 'user.email';
    declare colTelephoneNumber varchar(30) default 'user.telephone_number';
    declare colRoleName varchar(20) default 'role.name';
    
    set @SQLStatementBirthDate = '(select date_format(birth_date, "%Y-%m-%d"))';
    set @SQLStatement = 'select user.id, user.name, user.surname, user.birth_date, user.pesel, user.document_id,
     user.email, user.telephone_number, role.name as ''role_name'' from user join user_roles 
    on user.id = user_roles.user_id join role on role.id = user_roles.role_id ';
    if searchValue != '' then
		set @SQLStatement = concat(@SQLStatement, 'where ', colname, ' like("%', searchValue, '%")', ' OR');
		set @SQLStatement = concat(@SQLStatement, ' ', colSurname, ' like("%', searchValue, '%")', ' OR');
        set @SQLStatement = concat(@SQLStatement, ' ', @SQLStatementBirthDate, ' like("%', searchValue, '%")', ' OR');
        set @SQLStatement = concat(@SQLStatement, ' ', colDocumentId, ' like("%', searchValue, '%")', ' OR');
        set @SQLStatement = concat(@SQLStatement, ' ', colEmail, ' like("%', searchValue, '%")', ' OR');
        set @SQLStatement = concat(@SQLStatement, ' ', colTelephoneNumber, ' like("%', searchValue, '%")', ' OR');
        set @SQLStatement = concat(@SQLStatement, ' ', colRoleName, ' like("%', searchValue, '%")');
    end if;
    set @SQLStatement = concat(@SQLStatement, ' ', 'order by', ' ', columnName);
	set @SQLStatement = concat(@SQLStatement, ' ', orderDir);
	set @SQLStatement = concat(@SQLStatement, ' ', 'limit', ' ', length);
	set @SQLStatement = concat(@SQLStatement, ' ', 'offset', ' ', recordStart);
    prepare stmt from @SQLStatement;
    execute stmt;
end //

/* TEST PURPOSE PROCEDURES */
drop procedure if exists insertKartsWithRandomData;
DELIMITER //
create procedure insertKartsWithRandomData(in numberOfKarts int)
begin
	declare i int default 0;
    declare prize int;
    declare kartName varchar(20);
	while i < numberOfKarts do
		select floor(rand() * 100) into prize;
        select lpad(conv(floor(rand()*pow(36,6)), 10, 36), 6, 0) into kartName;
		insert into kart(availability, prize, name) values (1, prize, kartName);
        set i = i + 1;
    end while;
end //

drop procedure if exists insertUsersWithRandomData;
DELIMITER //
create procedure insertUsersWithRandomData(in numberOfUsers int)
begin
	declare i int default 0;
    declare userName varchar(20);
    declare surname varchar(20);
    declare birth_date date;
    declare pesel varchar(11);
    declare document_id varchar(9);
    declare email varchar(45);
    declare telephone_number varchar(15);
    declare role_id int;
    declare inserted_user_id int;
	while i < numberOfUsers do
		select lpad(conv(floor(rand()*pow(36,6)), 10, 36), 6, 0) into userName;
        select lpad(conv(floor(rand()*pow(36,6)), 10, 36), 6, 0) into surname;
        SELECT FROM_UNIXTIME(RAND() * 2147483647) into birth_date;
        select lpad(conv(floor(rand()*pow(36,6)), 10, 36), 6, 0) into pesel;
        select lpad(conv(floor(rand()*pow(36,6)), 10, 36), 6, 0) into document_id;
		select lpad(conv(floor(rand()*pow(36,6)), 10, 36), 6, 0) into email;
        select lpad(conv(floor(rand()*pow(36,6)), 10, 36), 9, 0) into telephone_number;
		if (i % 2 = 0) then
			set role_id = 1;
        else
			set role_id = 2;
        end if;
		insert into user(password, surname, name, birth_date, pesel, document_id, email, telephone_number) 
        values ('asdash123', surname, userName, birth_date, pesel, document_id, email, telephone_number);
        select last_insert_id() into inserted_user_id;
        insert into user_roles(user_ID, role_ID) values (inserted_user_id, role_id);
        set i = i + 1;
    end while;
end //

drop procedure if exists getLapsForSession;
DELIMITER //
create procedure getLapsForSession (in sessionId int, in userId int)
begin 
	select * from lap where lap_session_id = sessionId and user_id = userId;
end //