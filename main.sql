CREATE DATABASE AirportDB;
go
use AirportDB;
go

CREATE TABLE Flights (
    flight_id INT PRIMARY KEY,
    flight_number VARCHAR(50),
    departure_city VARCHAR(100),
    arrival_city VARCHAR(100),
    departure_time DATETIME,
    arrival_time DATETIME,
    flight_duration INT,
    available_seats INT,
    price DECIMAL(10, 2)
);
go
CREATE TABLE Passengers (
    passenger_id INT PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(100),
    phone_number VARCHAR(100)
);
go
CREATE TABLE Tickets (
    ticket_id INT PRIMARY KEY,
    flight_id INT,
    passenger_id INT,
    ticket_class VARCHAR(10) CHECK (ticket_class IN ('Economy', 'Business')),
    seat_number VARCHAR(10),
    ticket_price DECIMAL(10, 2),
    FOREIGN KEY (flight_id) REFERENCES Flights(flight_id),
    FOREIGN KEY (passenger_id) REFERENCES Passengers(passenger_id)
);
go
CREATE TABLE Cities (
    city_id INT PRIMARY KEY,
    city_name VARCHAR(100)
);
go
CREATE TABLE Flight_Cities (
    flight_id INT,
    city_id INT,
    FOREIGN KEY (flight_id) REFERENCES Flights(flight_id),
    FOREIGN KEY (city_id) REFERENCES Cities(city_id)
);
go
CREATE TABLE Flight_tickets (
    flight_id INT,
    ticket_id INT,
    FOREIGN KEY (flight_id) REFERENCES Flights(flight_id),
    FOREIGN KEY (ticket_id) REFERENCES Tickets(ticket_id)
);
go

CREATE TABLE Flight_Log (
    log_id INT PRIMARY KEY IDENTITY(1,1),
    flight_id INT,
    change_type VARCHAR(50),
    change_time DATETIME
);
go

CREATE TRIGGER trg_update_available_seats_after_insert
ON Tickets
AFTER INSERT
AS
BEGIN
    UPDATE Flights
    SET available_seats = available_seats - 1
    WHERE flight_id IN (SELECT flight_id FROM inserted);
END;
go

CREATE TRIGGER trg_update_available_seats_after_delete
ON Tickets
AFTER DELETE
AS
BEGIN
    UPDATE Flights
    SET available_seats = available_seats + 1
    WHERE flight_id IN (SELECT flight_id FROM deleted);
END;
go

CREATE TRIGGER trg_prevent_booking_if_no_seats
ON Tickets
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Flights WHERE flight_id IN (SELECT flight_id FROM inserted) AND available_seats <= 0)
    BEGIN
        RAISERROR ('No available seats for this flight.', 16, 1);
    END
    ELSE
    BEGIN
        INSERT INTO Tickets (ticket_id, flight_id, passenger_id, ticket_class, seat_number, ticket_price)
        SELECT ticket_id, flight_id, passenger_id, ticket_class, seat_number, ticket_price FROM inserted;
    END
END;
go

CREATE TRIGGER trg_log_flight_changes
ON Flights
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    IF EXISTS (SELECT * FROM inserted)
    BEGIN
        INSERT INTO Flight_Log (flight_id, change_type, change_time)
        SELECT flight_id, 'INSERT/UPDATE', GETDATE() FROM inserted;
    END
    IF EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO Flight_Log (flight_id, change_type, change_time)
        SELECT flight_id, 'DELETE', GETDATE() FROM deleted;
    END
END;
go

CREATE TRIGGER trg_update_flight_duration
ON Flights
AFTER UPDATE
AS
BEGIN
    IF UPDATE(departure_time) OR UPDATE(arrival_time)
    BEGIN
        UPDATE Flights
        SET flight_duration = DATEDIFF(MINUTE, departure_time, arrival_time)
        WHERE flight_id IN (SELECT flight_id FROM inserted);
    END
END;
go

INSERT INTO Flights (flight_id, flight_number, departure_city, arrival_city, departure_time, arrival_time, flight_duration, available_seats, price)
VALUES (1, 'AA123', 'New York', 'Los Angeles', '2023-12-01 08:00:00', '2023-12-01 11:00:00', 180, 150, 300.00),
       (2, 'BA456', 'London', 'Paris', '2023-12-02 09:00:00', '2023-12-02 10:30:00', 90, 200, 150.00),
       (3, 'CA789', 'Beijing', 'Shanghai', '2023-12-03 07:00:00', '2023-12-03 09:00:00', 120, 180, 200.00),
       (4, 'DA012', 'Sydney', 'Melbourne', '2023-12-04 06:00:00', '2023-12-04 08:00:00', 120, 160, 180.00),
       (5, 'EA345', 'Tokyo', 'Osaka', '2023-12-05 05:00:00', '2023-12-05 07:00:00', 120, 170, 220.00);
go

INSERT INTO Passengers (passenger_id, first_name, last_name, email, phone_number)
VALUES (1, 'John', 'Doe', 'john.doe@example.com', '123-456-7890'),
       (2, 'Jane', 'Smith', 'jane.smith@example.com', '234-567-8901'),
       (3, 'Alice', 'Johnson', 'alice.johnson@example.com', '345-678-9012'),
       (4, 'Bob', 'Brown', 'bob.brown@example.com', '456-789-0123'),
       (5, 'Charlie', 'Davis', 'charlie.davis@example.com', '567-890-1234');
go

INSERT INTO Tickets (ticket_id, flight_id, passenger_id, ticket_class, seat_number, ticket_price)
VALUES (1, 1, 1, 'Economy', '12A', 300.00),
       (2, 2, 2, 'Business', '1B', 150.00),
       (3, 3, 3, 'Economy', '15C', 200.00),
       (4, 4, 4, 'Business', '2D', 180.00),
       (5, 5, 5, 'Economy', '18E', 220.00);
go

INSERT INTO Cities (city_id, city_name)
VALUES (1, 'New York'),
       (2, 'Los Angeles'),
       (3, 'London'),
       (4, 'Paris'),
       (5, 'Beijing');
go

INSERT INTO Flight_Cities (flight_id, city_id)
VALUES (1, 1),
       (2, 2),
       (3, 3),
       (4, 4),
       (5, 5);
go

INSERT INTO Flight_tickets (flight_id, ticket_id)
VALUES (1, 1),
       (2, 2),
       (3, 3),
       (4, 4),
       (5, 5);
go

SELECT
    flight_number,
    departure_city,
    arrival_city,
    departure_time,
    arrival_time,
    flight_duration,
    available_seats,
    price
FROM
    Flights
WHERE
    arrival_city = 'Tokyo'
    AND CAST(departure_time AS DATE) = '2023-12-05'
ORDER BY
    departure_time;
go

SELECT
    flight_number,
    departure_city,
    arrival_city,
    departure_time,
    arrival_time,
    flight_duration,
    available_seats,
    price
FROM
    Flights
ORDER BY
    flight_duration DESC
OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY;
go

SELECT
    flight_number,
    departure_city,
    arrival_city,
    departure_time,
    arrival_time,
    flight_duration,
    available_seats,
    price
FROM
    Flights
WHERE
    flight_duration > 120;
go

SELECT
    arrival_city,
    COUNT(*) AS number_of_flights
FROM
    Flights
GROUP BY
    arrival_city;
go

SELECT
    TOP 1 arrival_city,
    COUNT(*) AS number_of_flights
FROM
    Flights
GROUP BY
    arrival_city
ORDER BY
    number_of_flights DESC;
go

DECLARE @month INT = 12;

SELECT
    arrival_city,
    COUNT(*) AS number_of_flights,
    SUM(COUNT(*)) OVER () AS total_flights
FROM
    Flights
WHERE
    MONTH(departure_time) = @month
GROUP BY
    arrival_city;
go

SELECT
    f.flight_number,
    f.departure_city,
    f.arrival_city,
    f.departure_time,
    f.arrival_time,
    f.flight_duration,
    f.available_seats,
    f.price
FROM
    Flights f
JOIN
    Tickets t ON f.flight_id = t.flight_id
WHERE
    CAST(f.departure_time AS DATE) = CAST(GETDATE() AS DATE)
    AND t.ticket_class = 'Business'
    AND f.available_seats > 0;
go

SELECT
    f.flight_number,
    COUNT(t.ticket_id) AS number_of_tickets_sold,
    SUM(t.ticket_price) AS total_revenue
FROM
    Flights f
JOIN
    Tickets t ON f.flight_id = t.flight_id
WHERE
    CAST(f.departure_time AS DATE) = '2023-12-05'
GROUP BY
    f.flight_number;
go

SELECT
    f.flight_number,
    COUNT(t.ticket_id) AS number_of_tickets_sold
FROM
    Flights f
JOIN
    Tickets t ON f.flight_id = t.flight_id
WHERE
    CAST(f.departure_time AS DATE) = '2023-12-05'
GROUP BY
    f.flight_number;
go

SELECT
    f.flight_number,
    c.city_name AS arrival_city
FROM
    Flights f
JOIN
    Flight_Cities fc ON f.flight_id = fc.flight_id
JOIN
    Cities c ON fc.city_id = c.city_id;
go

use master;
go
drop database AirportDB;
go

