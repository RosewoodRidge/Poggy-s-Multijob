-- Add the new column to the marshal_multi_jobs table
ALTER TABLE marshal_multi_jobs
ADD joblabel VARCHAR(255);

-- Original SQL 
CREATE TABLE marshal_multi_jobs (
		`cid` INT(11) NOT NULL,
		`job` varchar(255) NOT NULL,
		`jobgrade` INT(11) NOT NULL,
		`firstname` varchar(255) NOT NULL,
		`lastname` varchar(255) NOT NULL,
		`lastonline` varchar(255) NOT NULL,
		PRIMARY KEY (`cid`, `job`)
);

-- Updated SQL with the new column 'joblabel'
CREATE TABLE marshal_multi_jobs (
    `cid` INT(11) NOT NULL,
    `job` varchar(255) NOT NULL,
    `joblabel` varchar(255) DEFAULT NULL,
    `jobgrade` INT(11) NOT NULL,
    `firstname` varchar(255) NOT NULL,
    `lastname` varchar(255) NOT NULL,
    `lastonline` varchar(255) NOT NULL,
    PRIMARY KEY (`cid`, `job`)
);