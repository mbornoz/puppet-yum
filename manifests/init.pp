# = Class: yum
#
# This class manages yum repositories for RedHat based distros:
# RHEL, Centos, Scientific Linux 
#
# Copyright 2008, admin(at)immerda.ch
# Copyright 2008, Puzzle ITC GmbH
# Marcel Härry haerry+puppet(at)puzzle.ch
# Simon Josi josi+puppet(at)puzzle.ch
#
# This program is free software; you can redistribute
# it and/or modify it under the terms of the GNU
# General Public License version 3 as published by
# the Free Software Foundation.
#
# Apapted for Example42 by Alessandro Franceschi
#
# == Parameters
#
# [*update*]
#   If you want yum automatic updates. Possibile values:
#   cron - Updates in a cronjob
#   updatesd - Updates via updatesd (Only on Centos/RedHat/SL 5)
#   false/no - Automatic updates disabled (Default)
#
# [*extrarepo*]
#   If you want to enable some (supported) extra repositories
#   Can be an array. Default: 'epel'
#   (Epel is used by many modules)
#
# [*plugins_source_dir*]
#   The path of the plugins configuration directory
#
# [*clean_repos*]
#   Boolean. Defines if you want to cleanup the yum.repos.d dir
#   and be sure that it contains only files managed by Puppet
#   Default: false
#
# [*my_class*]
#   Name of a custom class to autoload to manage module's customizations
#   If defined, yum class will automatically "include $my_class"
#   Can be defined also by the (top scope) variable $yum_myclass
#
# [*source*]
#   Sets the content of source parameter for main configuration file
#   If defined, yum main config file will have the param: source => $source
#   Can be defined also by the (top scope) variable $yum_source
#
# [*source_dir*]
#   If defined, the whole yum configuration directory content is retrieved
#   recursively from the specified source
#   (source => $source_dir , recurse => true)
#   Can be defined also by the (top scope) variable $yum_source_dir
#
# [*source_dir_purge*]
#   If set to true (default false) the existing configuration directory is
#   mirrored with the content retrieved from source_dir
#   (source => $source_dir , recurse => true , purge => true)
#   Can be defined also by the (top scope) variable $yum_source_dir_purge
#
# [*template*]
#   Sets the path to the template to use as content for main configuration file
#   If defined, yum main config file has: content => content("$template")
#   Note source and template parameters are mutually exclusive: don't use both
#   Can be defined also by the (top scope) variable $yum_template
#
# [*options*]
#   An hash of custom options to be used in templates for arbitrary settings.
#   Can be defined also by the (top scope) variable $yum_options
#
# [*absent*]
#   Set to 'true' to remove package(s) installed by module
#   Can be defined also by the (top scope) variable $yum_absent
#
# [*disable*]
#   Set to 'true' to disable service(s) managed by module
#   Can be defined also by the (top scope) variable $yum_disable
#
# [*disableboot*]
#   Set to 'true' to disable service(s) at boot, without checks if it's running
#   Use this when the service is managed by a tool like a cluster software
#   Can be defined also by the (top scope) variable $yum_disableboot
#
# [*puppi*]
#   Set to 'true' to enable creation of module data files that are used by puppi
#   Can be defined also by the (top scope) variables $yum_puppi and $puppi
#
# [*puppi_helper*]
#   Specify the helper to use for puppi commands. The default for this module
#   is specified in params.pp and is generally a good choice.
#   You can customize the output of puppi commands for this module using another
#   puppi helper. Use the define puppi::helper to create a new custom helper
#   Can be defined also by the (top scope) variables $yum_puppi_helper
#   and $puppi_helper
#
# [*debug*]
#   Set to 'true' to enable modules debugging
#   Can be defined also by the (top scope) variables $yum_debug and $debug
#
# [*audit_only*]
#   Set to 'true' if you don't intend to override existing configuration files
#   and want to audit the difference between existing files and the ones
#   managed by Puppet.
#   Can be defined also by the (top scope) variables $yum_audit_only
#   and $audit_only
#
# [*config_dir*]
#   Main configuration directory. Used by puppi
#
# [*config_file*]
#   Main configuration file path
#
# [*config_file_mode*]
#   Main configuration file path mode
#
# [*config_file_owner*]
#   Main configuration file path owner
#
# [*config_file_group*]
#   Main configuration file path group
#
# [*log_file*]
#   Log file(s). Used by puppi
#
class yum (
  $update              = params_lookup( 'update' ),
  $extrarepo           = params_lookup( 'extrarepo' ),
  $plugins_source_dir  = params_lookup( 'plugins_source_dir' ),
  $clean_repos         = params_lookup( 'clean_repos' ),
  $my_class            = params_lookup( 'my_class' ),
  $source              = params_lookup( 'source' ),
  $source_dir          = params_lookup( 'source_dir' ),
  $source_dir_purge    = params_lookup( 'source_dir_purge' ),
  $template            = params_lookup( 'template' ),
  $options             = params_lookup( 'options' ),
  $absent              = params_lookup( 'absent' ),
  $disable             = params_lookup( 'disable' ),
  $disableboot         = params_lookup( 'disableboot' ),
  $puppi               = params_lookup( 'puppi' , 'global' ),
  $puppi_helper        = params_lookup( 'puppi_helper' , 'global' ),
  $debug               = params_lookup( 'debug' , 'global' ),
  $audit_only          = params_lookup( 'audit_only' , 'global' ),
  $config_dir          = params_lookup( 'config_dir' ),
  $config_file         = params_lookup( 'config_file' ),
  $config_file_mode    = params_lookup( 'config_file_mode' ),
  $config_file_owner   = params_lookup( 'config_file_owner' ),
  $config_file_group   = params_lookup( 'config_file_group' ),
  $log_file            = params_lookup( 'log_file' )
  ) inherits yum::params {

  $bool_clean_repos=any2bool($clean_repos)
  $bool_source_dir_purge=any2bool($source_dir_purge)
  $bool_absent=any2bool($absent)
  $bool_disable=any2bool($disable)
  $bool_disableboot=any2bool($disableboot)
  $bool_puppi=any2bool($puppi)
  $bool_debug=any2bool($debug)
  $bool_audit_only=any2bool($audit_only)

  $osver = split($::operatingsystemrelease, '[.]') 

  $manage_service_enable = $yum::bool_disableboot ? {
    true    => false,
    default => $yum::bool_disable ? {
      true    => false,
      default => $yum::bool_absent ? {
        true  => false,
        false => true,
      },
    },
  }


  $manage_service_ensure = $yum::bool_disable ? {
    true    => 'stopped',
    default =>  $yum::bool_absent ? {
      true    => 'stopped',
      default => 'running',
    },
  }

  $manage_file = $yum::bool_absent ? {
    true    => 'absent',
    default => 'present',
  }

  $manage_audit = $yum::bool_audit_only ? {
    true  => 'all',
    false => undef,
  }

  $manage_file_replace = $yum::bool_audit_only ? {
    true  => false,
    false => true,
  }

  $manage_file_source = $yum::source ? {
    ''        => undef,
    default   => $yum::source,
  }

  $manage_file_content = $yum::template ? {
    ''        => undef,
    default   => template($yum::template),
  }


  if $yum::update == 'cron' { include yum::cron }
  if $yum::update == 'updatesd' and $osver[0] == '5' { include yum::updatesd }
  
  if $yum::extrarepo =~ /epel/ { include yum::repo::epel }
  if $yum::extrarepo =~ /rpmforge/ { include yum::repo::rpmforge }
  if $yum::extrarepo =~ /jpackage5/ { include yum::repo::jpackage5 }
  if $yum::extrarepo =~ /jpackage6/ { include yum::repo::jpackage6 }
  if $yum::extrarepo =~ /remi/ { include yum::repo::remi }
  if $yum::extrarepo =~ /tmz/ and $osver[0] != "4" { include yum::repo::tmz }
  if $yum::extrarepo =~ /puppetlabs/ and $osver[0] != "4" { include yum::repo::puppetlabs }
  if $yum::extrarepo =~ /puppetdevel/ and $osver[0] != "4" { include yum::repo::puppetdevel }

  case $operatingsystem {

  centos: {
    if $osver[0] == "6" { include yum::repo::centos6 }
    if $osver[0] == "5" { include yum::repo::centos5 }
    if $osver[0] == "4" { include yum::repo::centos4 }
    if $yum::extrarepo =~ /centos-testing/ { include yum::repo::centos_testing }
    if $yum::extrarepo =~ /karan/ { include yum::repo::karan }
  }

  redhat: {
  }

  scientific: {
    include yum::repo::sl
    if $yum::extrarepo =~ /centos-testing/ { include yum::repo::centos_testing }
    if $yum::extrarepo =~ /karan/ { include yum::repo::karan }
  }

  default: { }
  }

  # Yum Configuration file
  file { 'yum.conf':
    ensure  => $yum::manage_file,
    path    => $yum::config_file,
    mode    => $yum::config_file_mode,
    owner   => $yum::config_file_owner,
    group   => $yum::config_file_group,
    source  => $yum::manage_file_source,
    content => $yum::manage_file_content,
    replace => $yum::manage_file_replace,
    audit   => $yum::manage_audit,
  }

  # The whole yum configuration directory can be recursively overriden
  if $yum::source_dir {
    file { 'yum.dir':
      ensure  => directory,
      path    => $yum::config_dir,
      source  => $yum::source_dir,
      recurse => true,
      purge   => $yum::source_dir_purge,
      replace => $yum::manage_file_replace,
      audit   => $yum::manage_audit,
    }
  }

  ### Include custom class if $my_class is set
  if $yum::my_class {
    include $yum::my_class
  }


  ### Provide puppi data, if enabled ( puppi => true )
  if $yum::bool_puppi == true {
    $classvars=get_class_args()
    puppi::ze { 'yum':
      ensure    => $yum::manage_file,
      variables => $classvars,
      helper    => $yum::puppi_helper,
    }
  }

  ### Debugging, if enabled ( debug => true )
  if $yum::bool_debug == true {
    file { 'debug_yum':
      ensure  => $yum::manage_file,
      path    => "${settings::vardir}/debug-yum",
      mode    => '0640',
      owner   => 'root',
      group   => 'root',
      content => inline_template('<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime.*|path|timestamp|free|.*password.*|.*psk.*|.*key)/ }.to_yaml %>'),
    }
  }


}
