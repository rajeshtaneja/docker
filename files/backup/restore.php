<?php
define('CLI_SCRIPT', true);

require_once(__DIR__.'/config.php');

# Restore a course
require_once($CFG->dirroot . '/backup/util/includes/restore_includes.php');
require_once($CFG->dirroot . '/grade/querylib.php');
require_once($CFG->libdir . '/completionlib.php');

if (isset($argv[1])) {
    $backupfile=$argv[1];
} else {
    $backupfile='/opt/AllFeaturesBackup.mbz';
}

$backupid = 'abc';
$backuppath = $CFG->tempdir . '/backup/' . $backupid;
check_dir_exists($backuppath);
get_file_packer('application/vnd.moodle.backup')->extract_to_pathname($backupfile, $backuppath);

$course = $DB->get_record_select('course', 'shortname = ?', array("Features Demo"));
// If course is not present then create it.
if (!$course) {
    $newcourseid = restore_dbops::create_new_course(
        'Moodle Features Demo', 'Features Demo', 1);
    $rc = new restore_controller($backupid, $newcourseid,
        backup::INTERACTIVE_NO, backup::MODE_GENERAL, 2,
        backup::TARGET_NEW_COURSE);

    if ($rc->execute_precheck()) {
        $rc->execute_plan();
        $rc->destroy();
    }
}
