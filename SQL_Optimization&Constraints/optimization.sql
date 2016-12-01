-- Convert Subqueries to Inner Joins.
-- Only retrieve data that is actually needed.
-- Use 'LIMIT' if you only need a limited amount of rows.
-- Avoid using functions on the left hand-side of an operater.
-- Avoid '%' at the beginning of a 'LIKE'.

-- 1. Original: 0.188 seconds, 1 row returned.
SELECT 
    DISTINCT m.nameFirst, m.nameLast
FROM
    master m,
    pitching a,
    teams t
WHERE
    m.masterId = a.masterId
        AND t.teamId = a.teamId
        AND t.lgID = a.lgID
        AND t.name like '%Montreal Expos%'
        AND t.yearID = a.yearId
        AND a.w >= 20;
        
-- 2. Original: 0.297 seconds, 7 rows returned.
SELECT 
    h / ab as Average, h as Hits, ab as At_Bats, nameFirst as First_Name, nameLast as Last_Name, 
	batting.yearID as Year
FROM
    batting,
    master
WHERE
    ab is not null
        and batting.masterID = master.masterID
        AND master.masterID IN (SELECT 
            masterID
        FROM
            schoolsplayers
        WHERE
            schoolID in (SELECT 
                    schoolID
                FROM
                    schools
                WHERE
                    schoolName like '%Utah State%'))
order by year;

-- 0.078 Seconds.
SELECT ba.Average, ba.Hits, ba.At_Bats, nameFirst as First_Name, nameLast as Last_Name, Year
FROM master as m 
INNER JOIN (
	SELECT H / AB as Average, H as Hits, AB as At_Bats, yearid as Year, masterid
	FROM batting b
	WHERE (AB IS NOT NULL AND b.masterID IN (
		SELECT masterID
		FROM schoolsplayers
		WHERE schoolID IN (
			SELECT schoolID 
            FROM schools 
            WHERE (schoolName like '%Utah State%'))))) as ba
ON (m.masterid = ba.masterid) 
ORDER BY year;

-- 3. Original: 1.109 seconds, limited to 1000 rows.
SELECT distinct jeter.masterID, jeterT.masterID, jeterTY.masterID, jeterTT.masterID
FROM
    master m,
    appearances jeter,
    appearances jeterT,
	appearances jeterTY,
    appearances jeterTT
WHERE
         m.masterID = jeter.masterID
        AND m.nameLast = 'Jeter'
        AND m.nameFirst = 'Derek'
        AND     jeter.teamID = jeterT.teamID
        AND  jeter.yearID = jeterT.yearID
        AND  jeter.lgID = jeterT.lgID
        AND  jeter.masterID <> jeterT.masterID;
        
SELECT DISTINCT j.masterID, jT.masterID, jTY.masterID, jTT.masterID
FROM
    master m    
INNER JOIN (
	SELECT masterID, teamID, yearID, lgID
	FROM appearances) j ON (j.masterID = m.masterID)
INNER JOIN (
	SELECT masterID, teamID, yearID, lgID
	FROM appearances) jT ON (jT.teamID = j.teamID AND jT.yearID = j.yearID AND jt.lgID = j.lgID AND 
		jT.masterID <> j.masterID)
INNER JOIN (
	SELECT masterID
	FROM appearances) jTY ON (jTY.masterID = j.masterID)
INNER JOIN (
	SELECT masterID
	FROM appearances) jTT ON (jTT.masterID = j.masterID)
WHERE
    m.nameLast = 'Jeter'
    AND m.nameFirst = 'Derek';
        
-- 4. Original: 0.125 seconds, 154 rows returned.
SELECT name, yearID, W
FROM teams as T
WHERE W = (
	SELECT MAX(W)
    FROM teams as y
    WHERE (t.yearID = y.yearID));
                
-- Optimized:

       
-- 5. 251.156 seconds, 93 rows returned.
SELECT C.yearID as year, name as teamName, C.lgID as league, D.cnt as totalBatters, C.cnt as aboveAverageBatters
FROM (
	SELECT COUNT(masterID) as cnt, A.yearID, A.teamID, A.lgID
    FROM (
		SELECT masterID, teamID, yearID, lgID, SUM(AB), SUM(H), SUM(H) / SUM(AB) as avg
    FROM
        batting
    GROUP BY teamID , yearID , lgID , masterID) B, (select 
        teamID,
            yearID,
            lgID,
            sum(AB),
            sum(H),
            sum(H) / sum(AB) as avg
    FROM
        batting
    WHERE ab is not null
    GROUP BY teamID , yearID , lgID) A
    WHERE
        A.avg >= B.avg AND A.teamID = B.teamID
            AND A.yearID = B.yearID
            AND A.lgID = B.lgID
    GROUP BY teamID , yearID , lgID) C,
    (SELECT 
        count(masterID) as cnt, yearID, teamID, lgID
    FROM
        batting
    WHERE ab is not null
    GROUP BY yearID , teamID , lgID) D, 
    teams
WHERE
    C.cnt / D.cnt >= 0.75
        AND C.yearID = D.yearID
        AND C.teamID = D.teamID
        AND C.lgID = D.lgID
        AND teams.yearID = C.yearID
        AND teams.lgID = C.lgID
        AND teams.teamID = C.teamID;
        
-- 6. 0.875 seconds, 281 rows returned.
SELECT distinct
    master.nameFirst as first_name, master.nameLast as last_name
FROM
    (SELECT 
        b.masterID as ID, b.yearID as year
    FROM
        batting b, teams t
    WHERE
        name = 'New York Yankees'
            and b.teamID = t.teamID
            and b.yearID = t.yearID
            and t.lgID = b.lgID) y1,
    (SELECT 
        b.masterID as ID, b.yearID as year
    FROM
        batting b, teams t
    WHERE
        name = 'New York Yankees'
            and b.teamID = t.teamID
            and b.yearID = t.yearID
            and t.lgID = b.lgID) y2,
    (SELECT 
        b.masterID as ID, b.yearID as year
    FROM
        batting b, teams t
    WHERE
        name = 'New York Yankees'
            and b.teamID = t.teamID
            and b.yearID = t.yearID
            and t.lgID = b.lgID) y3,
    (SELECT 
        b.masterID as ID, b.yearID as year
    FROM
        batting b, teams t
    WHERE
        name = 'New York Yankees'
            and b.teamID = t.teamID
            and b.yearID = t.yearID
            and t.lgID = b.lgID) y4,
    master
WHERE
    y1.id = y2.id and y2.id = y3.id
        and y3.id = y4.id
        and y1.year + 1 = y2.year
        and y2.year + 1 = y3.year
        and y3.year + 1 = y4.year
        and y4.id = master.masterID
ORDER BY master.nameLast, master.nameFirst;

-- 7.
SELECT 
    name,
    A.lgID,
    A.S as TotalSalary,
    A.yearID as Year,
    B.S as PreviousYearSalary,
    B.yearID as PreviousYear
FROM
    (SELECT 
        sum(salary) as S, yearID, teamID, lgID
    FROM
        salaries
    group by yearID , teamID , lgID) as A,
    (SELECT 
        sum(salary) as S, yearID, teamID, lgID
    FROM
        salaries
    group by yearID , teamID , lgID) as B,
    teams
WHERE
    A.yearID = B.yearID + 1
        AND (A.S * 2) <= (B.S)
        AND A.teamID = B.teamID
        AND A.lgID = B.lgID
        AND teams.yearID = A.yearID
        AND teams.lgID = A.lgID
        AND teams.teamID = A.teamID
       AND jeterT.masterID = jeterTY.masterID
       AND jeterTY.teamID = jeterTT.teamID
       and jeterTY.yearID = jeterTT.yearID
       AND jeterTY.lgID = jeterTT.lgID
      AND jeterTY.masterID <> jeterTT.masterID
      AND jeterTT.masterID <> jeter.masterID
      AND jeter.teamID <> jeterTY.teamID;