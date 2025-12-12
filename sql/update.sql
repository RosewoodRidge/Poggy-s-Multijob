-- Add joblabel column to marshal_multi_jobs if it doesn't exist
ALTER TABLE `marshal_multi_jobs`
ADD COLUMN IF NOT EXISTS `joblabel` VARCHAR(255) DEFAULT 'Unknown' AFTER `jobgrade`;

-- Update existing entries in marshal_multi_jobs with data from characters table
-- This assumes the characters table has a 'joblabel' column and the user is currently on that job
UPDATE `marshal_multi_jobs` mmj
INNER JOIN `characters` c ON mmj.cid = c.charidentifier AND mmj.job = c.job
SET mmj.joblabel = c.joblabel
WHERE c.joblabel IS NOT NULL;
