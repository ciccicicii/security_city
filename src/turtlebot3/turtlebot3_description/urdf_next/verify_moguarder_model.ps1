$ErrorActionPreference = "Stop"

$modelDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $modelDir)))
$urdf = Join-Path $modelDir "turtlebot3_moguarder.urdf.xacro"
$gazebo = Join-Path $modelDir "turtlebot3_moguarder.gazebo.xacro"
$commonProperties = Join-Path $modelDir "common_properties.xacro"
$teleop = Join-Path $workspaceRoot "src/turtlebot3/turtlebot3_teleop/nodes/turtlebot3_teleop_key"
$teleopLaunch = Join-Path $workspaceRoot "src/turtlebot3/turtlebot3_teleop/launch/turtlebot3_teleop_key.launch"
$worldLaunch = Join-Path $workspaceRoot "src/turtlebot3_simulations/turtlebot3_gazebo/launch/turtlebot3_world.launch"
$emptyWorldLaunch = Join-Path $workspaceRoot "src/turtlebot3_simulations/turtlebot3_gazebo/launch/turtlebot3_empty_world.launch"
$remoteLaunch = Join-Path $workspaceRoot "src/turtlebot3/turtlebot3_bringup/launch/turtlebot3_remote.launch"
$descriptionLaunch = Join-Path $workspaceRoot "src/turtlebot3/turtlebot3_bringup/launch/includes/description.launch.xml"
$navigationLaunch = Join-Path $workspaceRoot "src/turtlebot3/turtlebot3_navigation/launch/turtlebot3_navigation.launch"
$moveBaseLaunch = Join-Path $workspaceRoot "src/turtlebot3/turtlebot3_navigation/launch/move_base.launch"
$slamLaunch = Join-Path $workspaceRoot "src/turtlebot3/turtlebot3_slam/launch/turtlebot3_slam.launch"
$moguarderCostmap = Join-Path $workspaceRoot "src/turtlebot3/turtlebot3_navigation/param/costmap_common_params_moguarder.yaml"
$moguarderDwa = Join-Path $workspaceRoot "src/turtlebot3/turtlebot3_navigation/param/dwa_local_planner_params_moguarder.yaml"

if (-not (Test-Path $urdf)) {
  throw "Missing improved URDF/XACRO model: $urdf"
}

if (-not (Test-Path $gazebo)) {
  throw "Missing improved Gazebo model: $gazebo"
}

if (-not (Test-Path $commonProperties)) {
  throw "Missing local common properties include: $commonProperties"
}

if (-not (Test-Path $teleop)) {
  throw "Missing teleop keyboard file: $teleop"
}

$requiredLaunchFiles = @($teleopLaunch, $worldLaunch, $emptyWorldLaunch, $remoteLaunch, $descriptionLaunch, $navigationLaunch, $moveBaseLaunch, $slamLaunch)
foreach ($launchFile in $requiredLaunchFiles) {
  if (-not (Test-Path $launchFile)) {
    throw "Missing launch file: $launchFile"
  }
}

if (-not (Test-Path $moguarderCostmap)) {
  throw "Missing MoGuarder costmap params: $moguarderCostmap"
}

if (-not (Test-Path $moguarderDwa)) {
  throw "Missing MoGuarder DWA params: $moguarderDwa"
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
  "camera_mount_link",
  "camera_link",
  "top_comm_module_link",
  "left_range_link",
  "right_range_link",
  "top_payload_deck_link",
  "front_yellow_trim_link",
  "left_yellow_trim_link",
  "right_yellow_trim_link",
  "front_sensor_bezel_link",
  "left_sensor_bezel_link",
  "right_sensor_bezel_link",
  "deck_fastener_fl_link",
  "deck_fastener_fr_link",
  "deck_fastener_rl_link",
  "deck_fastener_rr_link",
  "wheel_left_front_link",
  "wheel_right_front_link",
  "wheel_left_rear_link",
  "wheel_right_rear_link"
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
  "camera_mount_joint",
  "camera_joint",
  "top_comm_module_joint",
  "left_range_joint",
  "right_range_joint",
  "top_payload_deck_joint",
  "front_yellow_trim_joint",
  "left_yellow_trim_joint",
  "right_yellow_trim_joint",
  "front_sensor_bezel_joint",
  "left_sensor_bezel_joint",
  "right_sensor_bezel_joint",
  "deck_fastener_fl_joint",
  "deck_fastener_fr_joint",
  "deck_fastener_rl_joint",
  "deck_fastener_rr_joint",
  "wheel_left_front_joint",
  "wheel_right_front_joint",
  "wheel_left_rear_joint",
  "wheel_right_rear_joint"
)

foreach ($jointName in $expectedJoints) {
  if ($jointNames -notcontains $jointName) {
    throw "Expected Low Scout structure joint missing: $jointName"
  }
}

if ($linkNames -contains "caster_back_link" -or $jointNames -contains "caster_back_joint") {
  throw "Four-wheel model should not keep the original rear caster"
}

foreach ($removedName in @("lidar_guard_left_link", "lidar_guard_right_link", "sensor_bridge_left_post_link", "sensor_bridge_right_post_link", "sensor_bridge_crossbar_link")) {
  if ($linkNames -contains $removedName) {
    throw "Removed self-occluding visual link should not remain: $removedName"
  }
}

foreach ($removedName in @("lidar_guard_left_joint", "lidar_guard_right_joint", "sensor_bridge_left_post_joint", "sensor_bridge_right_post_joint", "sensor_bridge_crossbar_joint")) {
  if ($jointNames -contains $removedName) {
    throw "Removed self-occluding visual joint should not remain: $removedName"
  }
}

$gazeboReferences = @($gazeboXml.robot.gazebo | Where-Object { $_.reference } | ForEach-Object { $_.reference })
foreach ($removedName in @("lidar_guard_left_link", "lidar_guard_right_link", "sensor_bridge_left_post_link", "sensor_bridge_right_post_link", "sensor_bridge_crossbar_link")) {
  if ($gazeboReferences -contains $removedName) {
    throw "Removed self-occluding visual Gazebo reference should not remain: $removedName"
  }
}

$scanJoint = $robot.joint | Where-Object { $_.name -eq "scan_joint" }
if (-not $scanJoint) {
  throw "scan_joint missing"
}

$scanOrigin = $scanJoint.origin.xyz
if ($scanOrigin -ne "0.060 0 0.095") {
  throw "Unexpected scan_joint origin: $scanOrigin"
}

$frontBumperJoint = $robot.joint | Where-Object { $_.name -eq "front_bumper_joint" }
if ($frontBumperJoint.origin.xyz -ne "0.118 0 0.043") {
  throw "Unexpected front_bumper_joint origin: $($frontBumperJoint.origin.xyz)"
}

$lidarMountJoint = $robot.joint | Where-Object { $_.name -eq "lidar_mount_joint" }
if ($lidarMountJoint.origin.xyz -ne "0.060 0 0.075") {
  throw "Unexpected lidar_mount_joint origin: $($lidarMountJoint.origin.xyz)"
}

$cameraMountJoint = $robot.joint | Where-Object { $_.name -eq "camera_mount_joint" }
if ($cameraMountJoint.origin.xyz -ne "0.080 0 0.105") {
  throw "Unexpected camera_mount_joint origin: $($cameraMountJoint.origin.xyz)"
}

$cameraJoint = $robot.joint | Where-Object { $_.name -eq "camera_joint" }
if ($cameraJoint.origin.xyz -ne "0.018 0 0.020") {
  throw "Unexpected camera_joint origin: $($cameraJoint.origin.xyz)"
}

$topCommJoint = $robot.joint | Where-Object { $_.name -eq "top_comm_module_joint" }
if ($topCommJoint.origin.xyz -ne "-0.030 0 0.115") {
  throw "Unexpected top_comm_module_joint origin: $($topCommJoint.origin.xyz)"
}

$topDeckJoint = $robot.joint | Where-Object { $_.name -eq "top_payload_deck_joint" }
if ($topDeckJoint.origin.xyz -ne "-0.015 0 0.088") {
  throw "Unexpected top_payload_deck_joint origin: $($topDeckJoint.origin.xyz)"
}

$frontTrimJoint = $robot.joint | Where-Object { $_.name -eq "front_yellow_trim_joint" }
if ($frontTrimJoint.origin.xyz -ne "0.077 0 0.061") {
  throw "Unexpected front_yellow_trim_joint origin: $($frontTrimJoint.origin.xyz)"
}

$frontShellJoint = $robot.joint | Where-Object { $_.name -eq "front_shell_joint" }
if (-not $frontShellJoint) {
  throw "front_shell_joint missing; improved body shell was not added"
}

$wheelLeftFrontJoint = $robot.joint | Where-Object { $_.name -eq "wheel_left_front_joint" }
$wheelRightFrontJoint = $robot.joint | Where-Object { $_.name -eq "wheel_right_front_joint" }
$wheelLeftRearJoint = $robot.joint | Where-Object { $_.name -eq "wheel_left_rear_joint" }
$wheelRightRearJoint = $robot.joint | Where-Object { $_.name -eq "wheel_right_rear_joint" }
if ($wheelLeftFrontJoint.origin.xyz -ne "0.070 0.085 0.040" -or
    $wheelRightFrontJoint.origin.xyz -ne "0.070 -0.085 0.040" -or
    $wheelLeftRearJoint.origin.xyz -ne "-0.085 0.085 0.040" -or
    $wheelRightRearJoint.origin.xyz -ne "-0.085 -0.085 0.040") {
  throw "Four-wheel joint origins do not match the UGV chassis layout"
}

$baseLink = $robot.link | Where-Object { $_.name -eq "base_link" }
if ([decimal]$baseLink.inertial.mass.value -ne 2.40) {
  throw "Base chassis mass should be 2.40kg for the scaled UGV baseline"
}

if ($baseLink.collision.origin.xyz -ne "-0.010 0 0.028") {
  throw "Base collision origin should keep the chassis below the low lidar scan plane, found $($baseLink.collision.origin.xyz)"
}

if ($baseLink.collision.geometry.box.size -ne "0.220 0.155 0.055") {
  throw "Base collision size should keep the chassis below the low lidar scan plane, found $($baseLink.collision.geometry.box.size)"
}

$wheelLinks = @("wheel_left_front_link", "wheel_right_front_link", "wheel_left_rear_link", "wheel_right_rear_link")
foreach ($wheelLinkName in $wheelLinks) {
  $wheelLink = $robot.link | Where-Object { $_.name -eq $wheelLinkName }
  if ([decimal]$wheelLink.inertial.mass.value -ne 0.18) {
    throw "$wheelLinkName mass should be 0.18kg"
  }

  if ([decimal]$wheelLink.collision.geometry.cylinder.radius -ne 0.045 -or [decimal]$wheelLink.collision.geometry.cylinder.length -ne 0.028) {
    throw "$wheelLinkName collision should use radius 0.045 and length 0.028"
  }
}

$gazeboRobot = $gazeboXml.robot
$wheelFriction = @{
  "wheel_left_front_link" = @("1.00", "0.35")
  "wheel_right_front_link" = @("1.00", "0.35")
  "wheel_left_rear_link" = @("1.00", "0.35")
  "wheel_right_rear_link" = @("1.00", "0.35")
}

foreach ($wheelName in $wheelFriction.Keys) {
  $wheelBlock = $gazeboRobot.gazebo | Where-Object { $_.reference -eq $wheelName }
  if (-not $wheelBlock) {
    throw "Missing Gazebo friction block for $wheelName"
  }

  $expected = $wheelFriction[$wheelName]
  if ([string]$wheelBlock.mu1 -ne $expected[0] -or [string]$wheelBlock.mu2 -ne $expected[1]) {
    throw "Unexpected friction for $wheelName, expected mu1=$($expected[0]) mu2=$($expected[1]), found mu1=$($wheelBlock.mu1) mu2=$($wheelBlock.mu2)"
  }
}

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

if ([decimal]$horizontal.min_angle -ne -2.35619 -or [decimal]$horizontal.max_angle -ne 2.35619) {
  throw "Laser horizontal angle should be front 270 degrees (-2.35619 to 2.35619), found $($horizontal.min_angle) to $($horizontal.max_angle)"
}

$range = $sensor.ray.range
if ([decimal]$range.max -ne 4.0) {
  throw "Laser max range should be 4.0, found $($range.max)"
}

$noise = $sensor.ray.noise
if ([decimal]$noise.stddev -ne 0.005) {
  throw "Laser noise stddev should be 0.005, found $($noise.stddev)"
}

$cameraBlock = $gazeboRobot.gazebo | Where-Object { $_.reference -eq "camera_link" }
if (-not $cameraBlock) {
  throw "camera_link Gazebo sensor block missing"
}

$cameraSensor = $cameraBlock.sensor
if ($cameraSensor.type -ne "camera" -or $cameraSensor.name -ne "moguarder_front_camera") {
  throw "Front camera sensor should be a Gazebo camera named moguarder_front_camera"
}

if ([int]$cameraSensor.update_rate -ne 30) {
  throw "Front camera update_rate should be 30, found $($cameraSensor.update_rate)"
}

if ([int]$cameraSensor.camera.image.width -ne 640 -or [int]$cameraSensor.camera.image.height -ne 480) {
  throw "Front camera image size should be 640x480"
}

if ($cameraSensor.plugin.filename -ne "libgazebo_ros_camera.so") {
  throw "Front camera should use libgazebo_ros_camera.so, found $($cameraSensor.plugin.filename)"
}

if ($cameraSensor.plugin.imageTopicName -ne "/camera/rgb/image_raw" -or
    $cameraSensor.plugin.cameraInfoTopicName -ne "/camera/rgb/camera_info" -or
    $cameraSensor.plugin.frameName -ne "camera_link") {
  throw "Front camera topics/frame are not configured for RGB model training"
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

$skidSteer = $gazeboRobot.gazebo.plugin | Where-Object { $_.name -eq "moguarder_skid_steer_controller" }
if (-not $skidSteer) {
  throw "moguarder_skid_steer_controller plugin missing"
}

if ($skidSteer.filename -ne "libgazebo_ros_skid_steer_drive.so") {
  throw "Skid-steer plugin filename should be libgazebo_ros_skid_steer_drive.so, found $($skidSteer.filename)"
}

if ($skidSteer.leftFrontJoint -ne "wheel_left_front_joint" -or
    $skidSteer.rightFrontJoint -ne "wheel_right_front_joint" -or
    $skidSteer.leftRearJoint -ne "wheel_left_rear_joint" -or
    $skidSteer.rightRearJoint -ne "wheel_right_rear_joint") {
  throw "Skid-steer plugin should drive all four wheel joints"
}

if ([decimal]$skidSteer.wheelSeparation -ne 0.170) {
  throw "wheelSeparation should be 0.170, found $($skidSteer.wheelSeparation)"
}

if ([decimal]$skidSteer.wheelDiameter -ne 0.090) {
  throw "wheelDiameter should be 0.090, found $($skidSteer.wheelDiameter)"
}

if ([decimal]$skidSteer.torque -ne 18) {
  throw "Skid-steer torque should be 18, found $($skidSteer.torque)"
}

if ($skidSteer.commandTopic -ne "cmd_vel" -or $skidSteer.odometryTopic -ne "odom") {
  throw "Skid-steer plugin topics should remain cmd_vel and odom"
}

$oldDiffDrive = $gazeboRobot.gazebo.plugin | Where-Object { $_.filename -eq "libgazebo_ros_diff_drive.so" }
if ($oldDiffDrive) {
  throw "Old diff-drive plugin should not remain in the skid-steer model"
}

$teleopText = Get-Content -Raw $teleop
if ($teleopText -notmatch "MOGUARDER_MAX_LIN_VEL = 0\.22") {
  throw "Teleop should define MoGuarder linear speed limit 0.22"
}

if ($teleopText -notmatch "MOGUARDER_MAX_ANG_VEL = 0\.75") {
  throw "Teleop should define MoGuarder angular speed limit 0.75"
}

if ($teleopText -notmatch 'rospy.get_param\("~speed", MOGUARDER_MAX_LIN_VEL\)' -or
    $teleopText -notmatch 'rospy.get_param\("~turn", MOGUARDER_MAX_ANG_VEL\)') {
  throw "Teleop should use private MoGuarder speed and turn parameters"
}

if ($teleopText -notmatch "MoGuarder Skid-Steer Keyboard Teleop") {
  throw "Teleop help text should describe the MoGuarder skid-steer mode"
}

if ($teleopText -notmatch "moveBindings" -or
    $teleopText -notmatch "'i': \([ ]*1, [ ]*0\)" -or
    $teleopText -notmatch "'I': \([ ]*1, [ ]*0\)" -or
    $teleopText -notmatch "'j': \([ ]*0, [ ]*1\)" -or
    $teleopText -notmatch "',': \([ ]*-1, [ ]*0\)" -or
    $teleopText -notmatch "'m': \([ ]*-1, [ ]*0\)" -or
    $teleopText -notmatch "'M': \([ ]*-1, [ ]*0\)") {
  throw "Teleop should use teleop_twist_keyboard-style directional bindings"
}

if ($teleopText -notmatch "speedBindings" -or
    $teleopText -notmatch "'q': \([ ]*1\.1, [ ]*1\.1\)" -or
    $teleopText -notmatch "'e': \([ ]*1, [ ]*1\.1\)") {
  throw "Teleop should use teleop_twist_keyboard-style speed bindings"
}

if ($teleopText -notmatch "class PublishThread" -or
    $teleopText -notmatch "key_timeout" -or
    $teleopText -notmatch "repeat_rate") {
  throw "Teleop should publish through a repeat thread with key timeout"
}

if ($teleopText -match "target_linear_vel = checkLinearLimitVelocity" -or
    $teleopText -match "target_angular_vel = checkAngularLimitVelocity") {
  throw "Teleop should not use TurtleBot3 incremental velocity accumulation"
}

$teleopLaunchText = Get-Content -Raw $teleopLaunch
if ($teleopLaunchText -notmatch '<param name="speed" value="0\.22"/' -or
    $teleopLaunchText -notmatch '<param name="turn" value="0\.75"/' -or
    $teleopLaunchText -notmatch '<param name="repeat_rate" value="10\.0"/' -or
    $teleopLaunchText -notmatch '<param name="key_timeout" value="0\.4"/') {
  throw "Teleop launch should set MoGuarder speed, turn, repeat_rate, and key_timeout"
}

$launchExpectations = @{
  $teleopLaunch = '<arg name="model" default="moguarder"'
  $worldLaunch = '<arg name="model" default="moguarder"'
  $emptyWorldLaunch = '<arg name="model" default="moguarder"'
  $remoteLaunch = '<arg name="model" default="moguarder"'
  $navigationLaunch = '<arg name="model" default="moguarder"'
  $moveBaseLaunch = '<arg name="model" default="moguarder"'
  $slamLaunch = '<arg name="model" default="moguarder"'
}

foreach ($launchFile in $launchExpectations.Keys) {
  $launchText = Get-Content -Raw $launchFile
  if ($launchText -notmatch [regex]::Escape($launchExpectations[$launchFile])) {
    throw "Launch file should default model to moguarder: $launchFile"
  }
}

$worldText = Get-Content -Raw $worldLaunch
$emptyWorldText = Get-Content -Raw $emptyWorldLaunch
$descriptionText = Get-Content -Raw $descriptionLaunch
if ($worldText -notmatch "urdf_next/turtlebot3_moguarder\.urdf\.xacro" -or
    $emptyWorldText -notmatch "urdf_next/turtlebot3_moguarder\.urdf\.xacro" -or
    $descriptionText -notmatch "urdf_next/turtlebot3_moguarder\.urdf\.xacro") {
  throw "MoGuarder launch descriptions should load URDF from urdf_next"
}

$dwaText = Get-Content -Raw $moguarderDwa
if ($dwaText -notmatch "max_vel_x: 0\.22" -or $dwaText -notmatch "max_vel_theta: 0\.75") {
  throw "MoGuarder DWA params should match the skid-steer teleop limits"
}

$costmapText = Get-Content -Raw $moguarderCostmap
if ($costmapText -notmatch "footprint: \[\[-0\.135, -0\.105\], \[-0\.135, 0\.105\], \[0\.165, 0\.105\], \[0\.165, -0\.105\]\]") {
  throw "MoGuarder costmap footprint should match the narrowed chassis"
}

Write-Host "MoGuarder improved model checks passed."
