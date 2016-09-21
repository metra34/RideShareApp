DROP TABLE IF EXISTS passengers CASCADE;
DROP TABLE IF EXISTS drivers CASCADE;
DROP TABLE IF EXISTS locations CASCADE;
DROP TABLE IF EXISTS rides CASCADE;
DROP TABLE IF EXISTS ratings CASCADE;

CREATE TABLE passengers (
    pid   SERIAL PRIMARY KEY, --added serial and primary key
    name  VARCHAR(127) NOT NULL
);

CREATE TABLE drivers (
    did   SERIAL PRIMARY KEY,    --added serial and primary key
    name  VARCHAR(127) NOT NULL, --added not null to all 3
    plate VARCHAR(15) NOT NULL,
    phone VARCHAR(15) NOT NULL
);

CREATE TABLE locations (
    did  INT PRIMARY KEY REFERENCES drivers(did) , --added foreign key
    lat  NUMERIC(9, 8),                      
    lon  NUMERIC(9, 8)                          
);

CREATE TABLE rides (
    rid           SERIAL PRIMARY KEY,             --added primary key
    pid           INT REFERENCES passengers(pid), --added foreign key
    did           INT REFERENCES drivers(did),    --added foreign key
    num_riders    INT NOT NULL 
    CONSTRAINT atleast_one_rider CHECK (num_riders > 0), 
    pickup_lat    NUMERIC(9, 8) NOT NULL,                
    pickup_lon    NUMERIC(9, 8) NOT NULL,
    dropoff_lat   NUMERIC(9, 8) NOT NULL,
    dropoff_lon   NUMERIC(9, 8) NOT NULL,
    fare          NUMERIC(6, 2) DEFAULT 0.00, 
    pickup_time   TIMESTAMP, 
    dropoff_time  TIMESTAMP,
    status        VARCHAR(15) NOT NULL DEFAULT 'requested' --added not null
	CHECK (status in ('requested', 'accepted', 'enroute', 'completed', 'cancelled')) --note that my cancelled has two "l"'s
);

CREATE TABLE ratings (
    rid     INT PRIMARY KEY REFERENCES rides(rid), --added primary key, foreign key
    rating  INT
);

--calculate the distance between two points in KM, formula was taken from http://andrew.hedges.name/experiments/haversine/
DROP FUNCTION IF EXISTS calc_distance(NUMERIC, NUMERIC, NUMERIC, NUMERIC) CASCADE;
CREATE FUNCTION calc_distance(lat1 NUMERIC, lon1 NUMERIC, lat2 NUMERIC, lon2 NUMERIC) RETURNS NUMERIC AS $$
	DECLARE
		a NUMERIC;
		c NUMERIC;
		d NUMERIC;
		dlon NUMERIC;
		dlat NUMERIC;
		r NUMERIC := 6371.00;
	BEGIN
		dlon := lon2 - lon1;
		dlat := lat2 - lat1;
		a := power(sin(dlat/2), 2.00) + cos(lat1) * cos(lat2) * power(sin(dlon/2), 2.00);
		c := 2 * atan2(sqrt(a), sqrt(1-a));
		d := round((r * c), 0);
		RETURN d;
	END
$$ LANGUAGE 'plpgsql';

-- calculate the fare of a completed trip
DROP FUNCTION IF EXISTS calc_fare(t NUMERIC, d NUMERIC) CASCADE;
CREATE FUNCTION calc_fare(t NUMERIC, d NUMERIC) RETURNS NUMERIC(6,2) AS $$
	DECLARE
		f NUMERIC(6,2);
	BEGIN
		f := 2.75 + round((0.30 * t + 0.90 * d) , 2);
		RETURN f;
	END
$$ LANGUAGE 'plpgsql';

--calculate fare trigger function
DROP FUNCTION IF EXISTS completed_fare(pickup TIMESTAMP, dropoff TIMESTAMP, lat1 NUMERIC, lon1 NUMERIC, lat2 NUMERIC, lon2 NUMERIC) CASCADE;
CREATE FUNCTION completed_fare(pickup TIMESTAMP, dropoff TIMESTAMP, lat1 NUMERIC, lon1 NUMERIC, lat2 NUMERIC, lon2 NUMERIC) RETURNS NUMERIC AS $$
	DECLARE
		dist NUMERIC; --distance between points in km
		dtime TIME; --difference in time between dropoff/ pickup times
		dhour NUMERIC;
		dmin NUMERIC;
		dsec NUMERIC;
		t NUMERIC; --total time of trip in minutes
		calc NUMERIC; --amount of fare
		
	BEGIN
		dtime := (dropoff - pickup);
	
		dhour := EXTRACT(HOUR FROM dtime);
		dmin := EXTRACT(MINUTE FROM dtime);
		dsec := EXTRACT(SECOND FROM dtime);
	
		dist := calc_distance(lat1, lon1, lat2, lon2);
		t := round((dhour*60 + dmin + dsec/60), 0);
		calc := calc_fare(t, dist);
		RETURN calc;
	END
$$ LANGUAGE 'plpgsql';

DROP FUNCTION IF EXISTS update_rides() CASCADE;
CREATE FUNCTION update_rides() RETURNS TRIGGER AS $$
	BEGIN
		--case: cancelling a cancelled ride
		IF (OLD.status='cancelled') THEN
			RAISE NOTICE 'CANCELLED RIDES CANT BE EDITED';
			RETURN NULL;
		END IF;
		
		--case: cancelling requested and accepted rides, while preventing the cancelling of enroute and completed rides
		IF ((OLD.status='enroute' OR OLD.status='completed') AND NEW.status='cancelled') THEN
			RAISE NOTICE 'RID(%) IS COMPLETED OR ENROUTE AND CANT BE CANCELLED', OLD.did;
			RETURN NULL;
		ELSIF (OLD.status='requested' AND NEW.status='cancelled') THEN
			RAISE NOTICE 'SUCCESSFULLY CANCELLED RID(%)', OLD.rid;
			RETURN NEW;
		ELSIF (OLD.status='accepted' AND NEW.status='cancelled') THEN
			RAISE NOTICE 'SUCCESSFULLY CANCELLED RID(%) -- FARE=$5.00 ', OLD.rid;
			NEW.fare:=5.00;
			RETURN NEW;
		END IF;
		
		--case: NULL did becomes NOT NULL OR attempt to update NOT NULL did
		IF (OLD.did IS NOT NULL AND NEW.did != OLD.did) THEN
			RAISE NOTICE 'DID CANT CHANGE, UPDATE FAILED';
			RETURN NULL;
		ELSIF (OLD.did IS NULL AND NEW.did IS NOT NULL) THEN
			RAISE NOTICE 'DID(%) ADDED FOR RID(%), NEW STATUS IS ACCEPTED', NEW.did, NEW.rid;
			NEW.status := 'accepted';
			RETURN NEW;
		END IF;
		
		--case: adding pickup time means a ride is now enroute, attempting to change a NOT NULL pickup_time is disallowed
		IF (OLD.pickup_time IS NOT NULL AND NEW.pickup_time != OLD.pickup_time) THEN
			RAISE NOTICE 'CANT CHANGE PICKUP TIME, UPDATE FAILED';
			RETURN NULL;
		ELSIF (OLD.pickup_time IS NULL and NEW.pickup_time IS NOT NULL AND NEW.did IS NOT NULL) THEN
			RAISE NOTICE 'PASSENGER PICKED UP AT:[%], STATUS IS ENROUTE', NEW.pickup_time;
			NEW.status := 'enroute';
			RETURN NEW;
		END IF;
		
		--case: adding dropoff time means ride has completed, attempting to change NOT NULL dropoff_time is disallowed, 
		--checking that dropoff/pickup times are logically valid
		IF (OLD.dropoff_time is NOT NULL AND NEW.dropoff_time != OLD.dropoff_time) THEN
			RAISE NOTICE 'CANT CHANGE DROPOFF TIME, UPDATE FAILED';
			RETURN NULL;
		ELSIF(NEW.dropoff_time < NEW.pickup_time) THEN
			RAISE NOTICE 'DROPOFF TIME:[%] MUST BE AFTER PICKUP TIME:[%], UPDATE FAILED', NEW.dropoff_time, NEW.pickup_time;
			RETURN NULL;
		ELSIF (OLD.dropoff_time is NULL and NEW.dropoff_time is NOT NULL AND NEW.did IS NOT NULL AND NEW.pickup_time IS NOT NULL) THEN
			NEW.status := 'completed';
			NEW.fare := completed_fare(NEW.pickup_time, NEW.dropoff_time, NEW.pickup_lat, NEW.pickup_lon, NEW.dropoff_lat, NEW.dropoff_lon);
			RAISE NOTICE 'PID(%) DROPPED OFF, STATUS IS COMPLETED -- FARE=$%', NEW.pid, NEW.fare;
			RETURN NEW;
		END IF;
		
		--All valid possibilities of UPDATE rides have been covered, reaching this point means USER is attempting an invalid update
		RAISE NOTICE 'NOT A VALID UPDATE. NO UPDATE EXECUTED.';
		RETURN NULL;
	END
$$ LANGUAGE 'plpgsql';

--maintain rides.status and rides.fare		
CREATE TRIGGER maintainRides BEFORE UPDATE
	ON rides FOR EACH ROW
	EXECUTE PROCEDURE update_rides();
	
--adds valid ratings	
DROP FUNCTION IF EXISTS check_rating_rid() CASCADE;	
CREATE FUNCTION check_rating_rid() RETURNS TRIGGER AS $$
	DECLARE
		stat VARCHAR;
		r INT = NEW.rid;
	BEGIN
		SELECT status INTO stat
			FROM rides
			WHERE rid=r;
		IF (stat!='completed') THEN
			RAISE NOTICE 'UNABLE TO RATE UNCOMPLETED RIDE';
			RETURN NULL;
		ELSIF (NEW.rating IS NOT NULL AND (NEW.rating<1 OR NEW.rating>5)) THEN
			RAISE NOTICE 'INVALID RATING, MUST BE BETWEEN [1 AND 5]';
			RETURN NULL;
		ELSE
			RAISE NOTICE 'RATING OF RID(%) SUCCESSFUL', NEW.rid;
            RETURN NEW;
        END IF;
	END
$$ LANGUAGE 'plpgsql';

--trigger for new ratings
CREATE TRIGGER can_rate BEFORE INSERT
	ON ratings FOR EACH ROW
	EXECUTE PROCEDURE check_rating_rid();
	
--check that pid doesn't already have an active ride request
DROP FUNCTION IF EXISTS duplicate_pid() CASCADE;	
CREATE FUNCTION duplicate_pid() RETURNS TRIGGER AS $$
	DECLARE
		exist_pid INT;
	BEGIN
		SELECT pid INTO exist_pid
			FROM rides
            WHERE (pid=NEW.pid AND (status='requested' OR status='accepted')); 
		IF (exist_pid IS NOT NULL) THEN
			RAISE NOTICE 'PID(%) ALREADY REQUESTED, NEW INSERT FAILED', NEW.pid;
			RETURN NULL;
		ELSE
			RAISE NOTICE 'CREATED A NEW RIDE REQUEST WITH RID(%) FOR PID(%)', NEW.rid, NEW.pid;
			RETURN NEW;
		END IF;
	END
$$ LANGUAGE 'plpgsql';
	
--trigger to prevent multiple ride requests from the same pid
CREATE TRIGGER rides_insert BEFORE INSERT
	ON rides FOR EACH ROW
	EXECUTE PROCEDURE duplicate_pid();

--view that displays rated driver's info by desc rating	
CREATE OR REPLACE VIEW driver_rating
	AS
	SELECT  drivers.did, name, plate, phone, rated
		FROM drivers LEFT OUTER JOIN
			(SELECT did, avg(rating) AS rated 
				FROM ratings NATURAL JOIN rides
				GROUP BY did) AS DD
		ON drivers.did=DD.did
		ORDER BY rated DESC;
		
--view that displays rated driver's info by desc rating	
CREATE OR REPLACE VIEW driver_rating2
	AS
	SELECT  drivers.did, name, plate, phone, rated
		FROM drivers NATURAL JOIN
			(SELECT did, avg(rating) AS rated 
				FROM ratings NATURAL JOIN rides
				GROUP BY did) AS DD
		ORDER BY rated DESC;

-- A view that removes all drivers with NULL locations from locations
CREATE OR REPLACE VIEW not_null_locations
	AS
	SELECT * 
		FROM locations
		WHERE lat IS NOT NULL AND lon IS NOT NULL;
