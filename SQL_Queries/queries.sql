-- Query 1 - LA Dodgers
-- List the first and last name of every
-- player who has ever played for the team
-- named "Los Angeles Dodgers".
SELECT DISTINCT nameFirst as first_name, nameLast as last_name
FROM master as M
JOIN appearances as A
	ON (M.masterID = A.masterID)
JOIN teams as T
	ON (A.teamID = T.teamID AND A.yearID = T.yearID)
WHERE T.name = "Los Angeles Dodgers"
ORDER BY nameLast;

-- Query 2 - Brooklyn and/or LA Dodgers
-- List the first and last name of every player
-- who has ONLY ever played for the team name
-- "LA Dodgers" OR "Brooklyn Dodgers".
SELECT name, nameFirst as first_name, nameLast as last_name
FROM master as M
WHERE M.masterID NOT IN (
	SELECT DISTINCT masterID
    FROM teams as T
    JOIN appearances as A
		ON (A.teamID = T.teamID AND A.yearID = T.yearID)
	WHERE T.name != "Los Angeles Dodgers" AND T.name != "Brooklyn Dodgers")
AND M.masterID IN (
	SELECT DISTINCT masterID
	FROM teams as T
    JOIN appearances as A
		ON (A.teamID = T.teamID AND A.yearID = T.yearID)
	WHERE T.name = "Los Angeles Dodgers" OR T.name = "Brooklyn Dodgers")
ORDER BY nameLast;

-- Query 2 - Brooklyn and/or LA Dodgers
-- List the first and last name of every player
-- who has ONLY ever played for the team name
-- "LA Dodgers" AND "Brooklyn Dodgers".
SELECT nameFirst as first_name, nameLast as last_name
FROM master as M
WHERE M.masterID NOT IN (
	SELECT DISTINCT masterID
    FROM teams as T
    JOIN appearances as A
		ON (A.teamID = T.teamID AND A.yearID = T.yearID)
	WHERE T.name != "Los Angeles Dodgers" AND T.name != "Brooklyn Dodgers")
AND M.masterID IN (
	SELECT DISTINCT masterID
	FROM teams as T
    JOIN appearances as A
		ON (A.teamID = T.teamID AND A.yearID = T.yearID)
	WHERE T.name = "Los Angeles Dodgers")
AND M.masterID IN (
	SELECT DISTINCT masterID
    FROM teams as T
    JOIN appearances as A
		ON (A.teamID = T.teamID AND A.yearID = T.yearID)
	WHERE T.name = "Brooklyn Dodgers")
ORDER BY nameLast;

-- Query 3 - Gold Glove Dodgers
-- List the first name, last name, position,
-- and year awarded for each player who has
-- won a "Gold Glove" award while playing for
-- the team named "LA Dodgers".
SELECT DISTINCT M.nameFirst as first_name, M.nameLast as last_name, AP.yearID as year, AP.notes as position
FROM master as M
JOIN appearances as A
	ON (M.masterID = A.masterID)
JOIN teams as T
	ON (A.teamID = T.teamID)
JOIN awardsplayers as AP
	ON (M.masterID = AP.masterID) 
WHERE T.name = "Los Angeles Dodgers" AND awardID = "GOLD GLOVE" AND AP.yearID = A.yearID
ORDER BY AP.yearID, M.nameLast ASC;

-- Query 4 - World Series Winner
-- List the team name of the world series
-- winner and the number of times
--  the team has won it.
SELECT DISTINCT name, COUNT(WSWin) as wins
FROM teams 
WHERE WSWin = 'Y'
GROUP BY name
ORDER BY wins ASC, name ASC;

-- Query 5 - USU Batters
-- List the first name, last name, year played,
-- and batting average of every player from the 
-- school named "Utah State University".
SELECT H as hits, AB as at_bats, (H/AB) as batting_average, nameFirst as first_name, nameLast as last_name, 
	yearID as year
FROM batting as B
JOIN master as M
	ON (B.masterID = M.masterID AND B.masterID IN (
		SELECT masterID
		FROM schoolsplayers
		WHERE schoolID IN (
			SELECT schoolID
			FROM schools
			WHERE schoolName = "Utah State University")))
AND B.AB IS NOT NULL
ORDER BY yearID, nameLast;

-- Query 6 - Bumper Salary Teams
-- List the total salary for two consecutive years,
-- team name, and year for every team that had 1.5
-- times the total salary as the previous year.        
SELECT DISTINCT T.name, T.lgID as league, S.oldyear, S.oldsalary as old_salary, S.yearID as year,
	S.salary as new_salary, FLOOR((S.salary / S.oldSalary) * 100) as percentage_increase
FROM teams as T
JOIN (
	SELECT S1.yearID, S1.teamID, SUM(S1.salary) as salary, S2.sumsalary as oldsalary, S2.yearID as oldYear
	FROM salaries as S1
	JOIN (
		SELECT SUM(salary) as sumsalary, yearID, teamID
		FROM salaries
		GROUP BY yearID, teamID) as S2
		ON (S1.teamID = S2.teamID AND S1.yearID = S2.yearID + 1)
	GROUP BY yearID, S1.teamID
    ) as S
	ON (T.teamID = S.teamID AND S.salary > 1.5 * S.oldsalary AND T.yearID = S.yearID)
ORDER BY S.yearID, T.name;

-- Query 7 - Red Sox Four
-- List the first and last name of every player
-- that has batted for the team named "Boston Red Sox"
-- in at least four consecutive years.
SELECT M.nameFirst, M.nameLast
FROM master as M
JOIN (
	SELECT DISTINCT Y1.masterID
    FROM teams as T
    JOIN batting as Y1
		ON (Y1.teamID = T.teamID AND Y1.yearID = T.yearID)
	JOIN batting as Y2
		ON (Y2.teamID = T.teamID AND Y1.masterID = Y2.masterID AND Y1.yearID = Y2.yearID -1)
	JOIN batting as Y3
		ON (Y3.teamID = T.teamID AND Y1.masterID = Y3.masterID AND Y1.yearID = Y3.yearID - 2)
	JOIN batting as Y4
		ON (Y4.teamID = T.teamID AND Y1.masterID = Y4.masterID AND Y1.yearID = Y4.yearID - 3)
    WHERE T.name = "New York Yankees") as MCBR
	ON (M.masterID = MCBR.masterID)
ORDER BY M.nameLast, M.nameFirst;

-- Query 8 - Home Run Kings
-- List, by year, the first name, last name, year, and number
-- of homeruns for every player that has had the most
-- homeruns in one year.
SELECT DISTINCT M.nameFirst as first_name, M.nameLast as last_name, batted.yearID as year, 
	batted.HR as homeruns
FROM master as M
JOIN (
	SELECT B.*
    FROM batting as B
	JOIN (
    	SELECT yearID, MAX(HR) as homeruns
		FROM batting
		GROUP BY yearID
    ) as MHR
		ON (B.yearID = MHR.yearID AND B.HR = MHR.homeruns)
) as batted
	ON (batted.masterID = M.masterID)
ORDER BY yearID, M.nameFirst, M.nameLast ASC;

-- Query 9 - Third Best Homeruns Each YEAR
-- List the first name, last name, year, and number of
-- homeruns  for every player that hit the third most
-- homeruns in one year.

-- View to find the third max number of homeruns for every year.
-- Must be run ONCE before the query below is run.    
CREATE VIEW thirdmaxhr as (
	SELECT B.yearID, MAX(B.HR) as homeruns
    FROM batting B
    JOIN (
    	SELECT B.yearID, MAX(B.HR) as homeruns
		FROM batting B
		JOIN (
        	SELECT yearID, MAX(HR) as homeruns
			FROM batting
			GROUP BY yearID
        ) as MHR
			ON (MHR.yearID = B.yearID AND B.HR < MHR.homeruns)
		GROUP BY B.yearID
    ) as SMHR
		ON (SMHR.yearID = B.yearID AND B.HR < SMHR.homeruns)
	GROUP BY B.yearID);
    
SELECT DISTINCT M.nameFirst as first_name, M.nameLast as last_name, batted.yearID as year, 
	batted.HR as homeruns
FROM master as M
JOIN (
	SELECT B.*
    FROM batting as B
	JOIN thirdmaxhr as TMHR
		ON (B.yearID = TMHR.yearID AND B.HR = TMHR.homeruns)
) as batted
	ON (batted.masterID = M.masterID)
ORDER BY yearID, M.nameLast, M.nameFirst ASC;

-- Query 10 - Triple Happy Teammates
-- List the team name, year, player's names, number of
-- triples hit for every team that had two or more players
-- with ten or more triples hit each.

-- View to keep track of the players and their teammates 
-- that hit ten or more triples in a sing season.
-- Must be run ONCE before the below query is run.
CREATE VIEW tentriples as (
	SELECT B1.masterID as masterID1, B2.masterID as masterID2, B1.yearID, B1.teamID, B1.3B, B2.3B2
    FROM batting as B1
    JOIN (
		SELECT yearID, masterID, teamID, 3B as 3B2
        FROM batting
        WHERE 3B >= 10
        ORDER BY yearID) as B2
        ON (B1.yearID = B2.yearID AND B1.teamID = B2.teamID)
	WHERE B1.3B >= 10 AND B1.masterID != B2.masterID
ORDER BY B1.yearID);

SELECT DISTINCT HTH.yearID as year, T.name team_name, M2.nameFirst as first_name1, M2.nameLast as last_name1,
	HTH.3B2 as triples1, M1.nameFirst as first_name2, M1.nameLast as last_name2, HTH.3B as triples2
FROM (
	SELECT TT1.*
    FROM tentriples as TT1
    WHERE EXISTS (
		SELECT *
        FROM tentriples as TT2
        WHERE TT2.masterID1 = TT1.masterID2 AND TT2.masterID2 = TT1.masterID1
			AND TT2.masterID1 < TT1.masterID1)) as HTH
JOIN master as M1
	ON (M1.masterID = HTH.masterID1)
JOIN master as M2
	ON (M2.masterID = HTH.masterID2)
JOIN teams as T
	ON (T.teamID = HTH.teamID AND T.yearID = HTH.yearID)
ORDER BY HTH.yearID, HTH.3B2, M2.nameLast, M2.nameFirst;

-- Query 11 - Ranking the Teams
-- List the name of each team in order of their winning
-- percentage for their entire history.

-- View to keep track of the team rankings.
-- Must be ran once before the following query is run.
CREATE VIEW rankings as (
	SELECT name, wins / gamesplayed as win_percentage, wins, losses
	FROM (
    	SELECT name, SUM(W) as wins, SUM(L) as losses, SUM(W) + SUM(L) as gamesplayed, 
			COUNT(yearID) as yearsactive
		FROM teams
		GROUP BY name
		ORDER BY name
	) as T
	ORDER BY win_percentage DESC);
   
-- Set the rank starting at zero.
-- Must be run every time the below query is run.
SET @rank = 0;

-- Did it wit the above view because doing it
-- all combined caused issues with the number ranking.
SELECT @rank:=@rank + 1 as rank, R.*
FROM rankings as R;

-- Query 12 - Casey Stengel's Pitchers
-- List the year, first name, and last name of every pitcher
-- that has played for a team managed by "Casey Stengel".
SELECT DISTINCT T.name as team_name, P.yearID as year, PM.nameFirst as first_name, PM.nameLast as last_name,
	M.nameFirst as manager_first_name, M.nameLast as manager_last_name
FROM pitching as P
JOIN managers as MG
	ON (MG.teamID = P.teamID AND MG.yearID = P.yearID)
JOIN teams as T
	ON (MG.teamID = T.teamID AND MG.yearID = T.yearID)
JOIN master as PM
	ON (P.masterID = PM.masterID)
JOIN master as M
	ON (MG.masterID = M.masterID)
WHERE M.nameFirst = "Casey" AND M.nameLast = "Stengel" AND P.yearID = MG.yearID
ORDER BY P.yearID, PM.nameLast, PM.nameFirst;

-- Query 13 - Two Degrees from Yogi Berra
-- List the name of every player who has been on a team with
-- a player that was once a teammate of "Yogi Berra".

-- View to keep track of yogi and every player 
-- who has ever been his teammate.
-- Must be run ONCE before the following query is run.
CREATE VIEW yogiandteammates as (
	SELECT DISTINCT M.masterID
    FROM master as M
    JOIN appearances A
		ON (M.masterID = A.masterID)
    JOIN (
		SELECT A.yearID, A.teamID
		FROM master as M
		JOIN appearances as A
			ON (A.masterID = M.masterID)
		WHERE M.nameFirst = "Yogi" AND M.nameLast = "Berra"
		) as Y
		ON (A.yearID = Y.yearID AND A.teamID = Y.teamID)
	ORDER BY A.teamID, A.yearID);
    
SELECT DISTINCT M.nameFirst as first_name, M.nameLast as last_name
FROM master as M
JOIN yogiandteammates as YT
	ON (M.masterID != YT.masterID)
JOIN appearances as A
	ON (M.masterID = A.masterID)
JOIN appearances as YTA
	ON (YT.masterID = YTA.masterID AND A.yearID = YTA.yearID AND A.teamID = YTA.teamID)
WHERE (M.nameFirst != "Yogi" AND M.nameLast != "Berra")
ORDER BY M.nameLast, M.nameFirst;

-- Qeury 14 - Rickey's Travels
-- List every team that "Rickey Henderson" has not played 
-- for that existed during his career.
SELECT DISTINCT name
FROM teams
WHERE yearID > year ((
	SELECT debut
    FROM master
    WHERE nameFirst = "Rickey" AND nameLast = "Henderson"))
AND yearID < year ((
	SELECT finalGame
    FROM master
    WHERE nameFirst = "Rickey" AND nameLast = "Henderson"))
AND teamID NOT IN (
	SELECT teamID
    FROM appearances
    WHERE masterID = (
		SELECT masterID
        FROM master
        WHERE nameFirst = "Rickey" AND nameLast = "Henderson"))
ORDER BY name;