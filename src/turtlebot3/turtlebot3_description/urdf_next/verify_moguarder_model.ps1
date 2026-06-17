$ErrorActionPreference = "Stop"

$modelDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$urdf = Join-Path $modelDir "turtlebot3_moguarder.urdf.xacro"
$gazebo = Join-Path $modelDir "turtlebot3_moguarder.gazebo.xacro"
$commonProperties = Join-Path $modelDir "common_properties.xacro"

if (-not (Test-Path $urdf)) {
  throw "Missing improved URDF/XACRO model: $urdf"
}

if (-not (Test-Path $gazebo)) {
  throw "Missing improved Gazebo model: $gazebo"
}

if (-not (Test-Path $commonProperties)) {
  throw "Missing local common properties include: $commonProperties"
}

$urdfXml = [xml](Get-Content -Raw $urdf)
$gazeboXml = [xml](Get-Content -Raw $gazebo)

$robot = $urdfXml.robot
if ($robot.name -ne "turtlebot3_moguarder") {
  throw "Unexpected robot name: $($robot.name)"
}

$includeFilenames = @($robot.include | ForEach-Object { $_.filename })
if ($includeFilenames -notcontains '$(find turtlebot3_description)/urdf_next/common_properties.xacro') {
  throw "URDF does not include the local common properties XACRO"
}

if ($includeFilenames -notcontains '$(find turtlebot3_description)/urdf_next/turtlebot3_moguarder.gazebo.xacro') {
  throw "URDF does not include the improved Gazebo XACRO"
}

$linkNames = @($robot.link | ForEach-Object { $_.name })
$jointNames = @($robot.joint | ForEach-Object { $_.name })

$expectedLinks = @(
  "center_body_link",
  "rear_module_link",
  "front_bumper_link",
  "left_side_plate_link",
  "right_side_plate_link",
  "lidar_mount_link",
  "lidar_guard_left_link",
  "lidar_guard_right_link",
  "top_comm_module_link",
  "left_range_link",
  "right_range_link",
  "top_payload_deck_link",
  "front_yellow_trim_link",
  "left_yellow_trim_link",
  "right_yellow_trim_link",
  "sensor_bridge_left_post_link",
  "sensor_bridge_right_post_link",
  "sensor_bridge_crossbar_link",
  "front_sensor_bezel_link",
  "left_sensor_bezel_link",
  "right_sensor_bezel_link",
  "deck_fastener_fl_link",
  "deck_fastener_fr_link",
  "deck_fastener_rl_link",
  "deck_fastener_rr_link"
)

foreach ($linkName in $expectedLinks) {
  if ($linkNames -notcontains $linkName) {
    throw "Expected Low Scout structure link missing: $linkName"
  }
}

$expectedJoints = @(
  "center_body_joint",
  "rear_module_joint",
  "front_bumper_joint",
  "left_side_plate_joint",
  "right_side_plate_joint",
  "lidar_mount_joint",
  "lidar_guard_left_joint",
  "lidar_guard_right_joint",
  "top_comm_module_joint",
  "left_range_joint",
  "right_range_joint",
  "top_payload_deck_joint",
  "front_yellow_trim_joint",
  "left_yellow_trim_joint",
  "right_yellow_trim_joint",
  "sensor_bridge_left_post_joint",
  "sensor_bridge_right_post_joint",
  "sensor_bridge_crossbar_joint",
  "front_sensor_bezel_joint",
  "left_sensor_bezel_joint",
  "right_sensor_bezel_joint",
  "deck_fastener_fl_joint",
  "deck_fastener_fr_joint",
  "deck_fastener_rl_joint",
  "deck_fastener_rr_joint"
)

foreach ($jointName in $expectedJoints) {
  if ($jointNames -notcontains $jointName) {
    throw "Expected Low Scout structure joint missing: $jointName"
  }
}

$scanJoint = $robot.joint | Where-Object { $_.name -eq "scan_joint" }
if (-not $scanJoint) {
  throw "scan_joint missing"
}

$scanOrigin = $scanJoint.origin.xyz
if ($scanOrigin -ne "0.035 0 0.085") {
  throw "Unexpected scan_joint origin: $scanOrigin"
}

$frontBumperJoint = $robot.joint | Where-Object { $_.name -eq "front_bumper_joint" }
if ($frontBumperJoint.origin.xyz -ne "0.105 0 0.030") {
  throw "Unexpected front_bumper_joint origin: $($frontBumperJoint.origin.xyz)"
}

$lidarMountJoint = $robot.joint | Where-Object { $_.name -eq "lidar_mount_joint" }
if ($lidarMountJoint.origin.xyz -ne "0.035 0 0.052") {
  throw "Unexpected lidar_mount_joint origin: $($lidarMountJoint.origin.xyz)"
}

$topCommJoint = $robot.joint | Where-Object { $_.name -eq "top_comm_module_joint" }
if ($topCommJoint.origin.xyz -ne "-0.030 0 0.115") {
  throw "Unexpected top_comm_module_joint origin: $($topCommJoint.origin.xyz)"
}

$topDeckJoint = $robot.joint | Where-Object { $_.name -eq "top_payload_deck_joint" }
if ($topDeckJoint.origin.xyz -ne "-0.015 0 0.088") {
  throw "Unexpected top_payload_deck_joint origin: $($topDeckJoint.origin.xyz)"
}

$bridgeCrossbarJoint = $robot.joint | Where-Object { $_.name -eq "sensor_bridge_crossbar_joint" }
if ($bridgeCrossbarJoint.origin.xyz -ne "0.035 0 0.128") {
  throw "Unexpected sensor_bridge_crossbar_joint origin: $($bridgeCrossbarJoint.origin.xyz)"
}

$frontTrimJoint = $robot.joint | Where-Object { $_.name -eq "front_yellow_trim_joint" }
if ($frontTrimJoint.origin.xyz -ne "0.077 0 0.061") {
  throw "Unexpected front_yellow_trim_joint origin: $($frontTrimJoint.origin.xyz)"
}

$frontShellJoint = $robot.joint | Where-Object { $_.name -eq "front_shell_joint" }
if (-not $frontShellJoint) {
  throw "front_shell_joint missing; improved body shell was not added"
}

$wheelLeftJoint = $robot.joint | Where-Object { $_.name -eq "wheel_left_joint" }
$wheelRightJoint = $robot.joint | Where-Object { $_.name -eq "wheel_right_joint" }
if ($wheelLeftJoint.origin.xyz -ne "0.0 0.075 0.023" -or $wheelRightJoint.origin.xyz -ne "0.0 -0.075 0.023") {
  throw "Wheel joint origins do not match the narrowed chassis"
}

$gazeboRobot = $gazeboXml.robot
$sensorBlock = $gazeboRobot.gazebo | Where-Object { $_.reference -eq "base_scan" }
if (-not $sensorBlock) {
  throw "base_scan Gazebo sensor block missing"
}

$sensor = $sensorBlock.sensor
if ([int]$sensor.update_rate -ne 10) {
  throw "Laser update_rate should be 10, found $($sensor.update_rate)"
}

$horizontal = $sensor.ray.scan.horizontal
if ([int]$horizontal.samples -ne 720) {
  throw "Laser samples should be 720, found $($horizontal.samples)"
}

$range = $sensor.ray.range
if ([decimal]$range.max -ne 4.0) {
  throw "Laser max range should be 4.0, found $($range.max)"
}

$noise = $sensor.ray.noise
if ([decimal]$noise.stddev -ne 0.005) {
  throw "Laser noise stddev should be 0.005, found $($noise.stddev)"
}

$leftRangeBlock = $gazeboRobot.gazebo | Where-Object { $_.reference -eq "left_range_link" }
$rightRangeBlock = $gazeboRobot.gazebo | Where-Object { $_.reference -eq "right_range_link" }
if (-not $leftRangeBlock -or -not $rightRangeBlock) {
  throw "Side range sensor Gazebo blocks are missing"
}

if ($leftRangeBlock.sensor.name -ne "moguarder_left_range" -or $rightRangeBlock.sensor.name -ne "moguarder_right_range") {
  throw "Side range sensor names are not configured correctly"
}

if ([int]$leftRangeBlock.sensor.ray.scan.horizontal.samples -ne 1 -or [int]$rightRangeBlock.sensor.ray.scan.horizontal.samples -ne 1) {
  throw "Side range sensors should use one ray sample each"
}

if ([decimal]$leftRangeBlock.sensor.ray.range.max -ne 0.8 -or [decimal]$rightRangeBlock.sensor.ray.range.max -ne 0.8) {
  throw "Side range sensor max range should be 0.8"
}

$diffDrive = $gazeboRobot.gazebo.plugin | Where-Object { $_.name -eq "moguarder_controller" }
if (-not $diffDrive) {
  throw "moguarder_controller diff-drive plugin missing"
}

if ([decimal]$diffDrive.wheelSeparation -ne 0.150) {
  throw "wheelSeparation should be 0.150, found $($diffDrive.wheelSeparation)"
}

if ([decimal]$diffDrive.wheelDiameter -ne 0.066) {
  throw "wheelDiameter should be 0.066, found $($diffDrive.wheelDiameter)"
}

Write-Host "MoGuarder improved model checks passed."
