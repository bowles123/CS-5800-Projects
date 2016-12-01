-- Constraint 1 
-- Default number of AB is 20.
ALTER TABLE batting 
ALTER AB SET DEFAULT 20;

-- Check that constraint works.
INSERT INTO batting(masterID, yearID) VALUE("blahblah", 2016);
SELECT * FROM batting
ORDER BY yearID desc;

-- Delete test row from the database.
DELETE FROM batting
WHERE masterID = "blahblah";

-- Constraint 2 
-- Player cannot have more hits than AB(At bats).
DROP TRIGGER IF EXISTS Hits_LessThanEqual_AtBats;

DELIMITER $$

CREATE TRIGGER Hits_LessThanEqual_AtBats BEFORE INSERT ON batting
	FOR EACH ROW BEGIN
		IF NEW.H > NEW.AB THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "'H' cannot be greater than 'AB'";
		END IF;
	END$$
    
DELIMITER ;

-- Check that constraint works.
INSERT INTO batting(masterID, yearID, AB, H) VALUE("blahblah", 2016, 45, 50);

-- Constraint 3 -- Check still might not work, verify could work in postgress?
-- League can only be one value in the Teams table.
DROP TRIGGER IF EXISTS NL_Or_AL;

DELIMITER $$

	CREATE TRIGGER NL_Or_AL BEFORE INSERT ON teams
		FOR EACH ROW BEGIN
			IF NEW.lgID != 'NL' AND NEW.lgID != 'AL' THEN
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "'lgID' must be 'AL' or 'NL'";
			END IF;
		END$$
	
DELIMITER ;	

-- Check that cosntraint works.
INSERT INTO teams(yearID, lgID, teamID, name) VALUE(2016, 'NA', 'BLA', "Blah Blahs");

-- Constraint 4 
-- When a team loses more than 161 in a season all batting records
-- for the team for that year should be deleted.
DROP TRIGGER IF EXISTS Delete_Bad_Team_Batting;

DELIMITER $$

CREATE TRIGGER Delete_Bad_Team_Batting AFTER INSERT ON teams
	FOR EACH ROW BEGIN
		IF NEW.L > 161 THEN
			DELETE FROM batting WHERE(batting.teamID = NEW.teamID AND batting.yearID = NEW.yearID);
		END IF;
	END$$

DELIMITER ;

-- Check that constraint works
INSERT INTO batting(masterID, yearID, teamID) VALUE('blahblah', 2016, 'BLA');
INSERT INTO teams(yearID, lgID, teamID, L, name) VALUE(2016, 'NL', 'BLA', 162, "Blah Blahs"); -- Safe mode error.

-- Delete test row from database.
DELETE FROM teams
WHERE(teamID = 'BLA' AND yearID = 2016);

DELETE FROM batting
WHERE(teamID = 'BLA' AND yearID = 2016 AND masterID = 'blahblah');

-- Constraint 5 
-- If a player wins the MVP, WS MVP, and a Gold Glove in the same season, 
-- they are automatically inducted into the Hall of Fame.
DROP TRIGGER IF EXISTS Add_To_HallofFame;

DELIMITER $$

CREATE TRIGGER Add_To_HallofFame AFTER INSERT ON awardsplayers
	FOR EACH ROW BEGIN
		IF (SELECT COUNT(awardID)
			FROM awardsplayers as A
            WHERE A.yearID = NEW.yearID AND A.masterID = NEW.masterID AND (
				NEW.awardID = 'Gold Glove'
                OR NEW.awardID = 'Most Valuable Player'
                OR NEW.awardID = 'World Series MVP')) = 3 THEN
			INSERT INTO halloffame (masterID, yearID, inducted) VALUE(NEW.masterID, NEW.yearID, 'Y');
		END IF;
	END$$
    
DELIMITER ; -- Not quite sure if this works.

-- Check that the constraint works.
INSERT INTO awardsplayers(masterID, awardID, yearID, lgID) VALUE("Blahblah", 'Gold Glove', 2016, 'NL');
INSERT INTO awardsplayers(masterID, awardID, yearID, lgID) VALUE("Blahblah", 'Most Valuable Player', 2016, 'NL');
INSERT INTO awardsplayers(masterID, awardID, yearID, lgID) VALUE("Blahblah", 'Word Series MVP', 2016, 'NL');

-- Delete test row from database.
DELETE FROM awardsplayers
WHERE(masterID = "Blahblah" AND yearID = 2016 AND lgID = 'NL');

DELETE FROM halloffame
WHERE(masterID = "Blahblah" AND yearID = 2016);

-- Constraint 6
-- Name in the teams table cannot be null.

-- Check doesn't work in MySQL, but verified query does work in Postgress,
-- with an added 'NOT VALID' at the end, which MySQL doesn't support.
DROP TRIGGER IF EXISTS Check_Null_Name;

DELIMITER $$

CREATE TRIGGER Check_Null_Name BEFORE INSERT ON teams
	FOR EACH ROW BEGIN
		IF NEW.name IS NULL THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Team 'name' cannot be null.";
		END IF;
	END$$
    
DELIMITER ;

-- Check that the constraint works.
INSERT INTO teams(yearID, lgID, teamID) VALUE(2016, 'AL', 'BB1');

-- Constraint 7 
-- Everybody has a unique name (first, last).
ALTER TABLE master ADD CONSTRAINT Unique_Name UNIQUE(nameFirst, nameLast); -- Duplicate entry for key 'Unique_Name', works?

-- Check that the constraint works.
INSERT INTO master(masterID, nameFirst, nameLast) VALUE("aablahblah", "Yogi", "Berra");