use carttrackdb;
drop database carttrackdb;
insert into role(name) values ('ROLE_USER'), ('ROLE_ADMIN');

insert into user(password, surname, name, birth_date, pesel, document_id, email, telephone_number) 
values ('$2y$13$PcP0CEbn.cINDhAwQ9C7ZOB2h0Ibs9xrZC9GOTivj.B7relaxfL6O', 'kowalski', 'jan', '1996-04-30', '123123', 'asd23', 'jan@gmail.com','505404404');
insert into user(password, surname, name, birth_date, pesel, document_id, email, telephone_number) 
values ('$2y$13$PcP0CEbn.cINDhAwQ9C7ZOB2h0Ibs9xrZC9GOTivj.B7relaxfL6O', 'admin', 'admin', '1996-04-30', '123123', 'asd23', 'admin@gmail.com','505404404');

insert into user_roles(user_ID, role_ID) values (1, 1);
insert into user_roles(user_ID, role_ID) values (2, 2);

insert into ride_time_dictionary(ride_count, time_per_ride) values (1, 10);
insert into trackinfo(id, street, city, telephone_number, hour_start, hour_end, facebook_link, instagram_link, email)
values (1, 'ul.Rojna 55', 'Łódz', '505-502-400', '14:00', '19:00', null, null, 'email@gmail.com');

call insertKartsWithRandomData(20);
call insertUsersWithRandomData(5000);
insert into kart(availability, prize, name) values 
(1, 25, 'gt5'), (0, 25, 'gt6'), (1, 30, 'gt7'), (1, 25, 'gt8');


call getUsers(0, 10, 'name', 'asc', '', 1);
call getReservations(0, 10, 'cost', 'asc', 'kowalski');

