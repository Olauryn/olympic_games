--create table for olympics_history
CREATE TABLE olympics_history (
id INT,
name VARCHAR,
sex VARCHAR,
age VARCHAR,
height VARCHAR,
weight VARCHAR,
team VARCHAR,
noc VARCHAR,
games VARCHAR,
year INT,
season VARCHAR,
city VARCHAR,
sport VARCHAR,
event VARCHAR,
medal VARCHAR);

--create table for olympics_noc_region
CREATE TABLE olympics_noc_region (
	noc VARCHAR,
	region VARCHAR,
	notes VARCHAR);
--select all data from the olympics_history and olympics_noc_region	
SELECT * FROM olympics_history;
SELECT * FROM olympics_noc_region;