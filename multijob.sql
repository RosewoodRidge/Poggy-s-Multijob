
CREATE TABLE marshal_multi_jobs (
		`cid` INT(11) NOT NULL,
		`job` varchar(255) NOT NULL,
		`jobgrade` INT(11) NOT NULL,
		`firstname` varchar(255) NOT NULL,
		`lastname` varchar(255) NOT NULL,
		`lastonline` varchar(255) NOT NULL,
		PRIMARY KEY (`cid`, `job`)
);

