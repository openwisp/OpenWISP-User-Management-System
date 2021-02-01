Project discontinued
--------------------

Please use [OpenWISP RADIUS](https://openwisp-radius.readthedocs.io/en/latest/).

The README is maintained below for historic purposes.

# OpenWISP User Management System

![Release](http://img.shields.io/github/release/openwisp/OpenWISP-User-Management-System.svg)

## What is it?

OpenWISP User Management System (OWUMS) is a Ruby on Rails application, capable of managing a wISP's user base.

OWUMS supports the following functionalities:
* user registration via mobile phone, ID card, credit card -Banca Sella Gestpay- fully compliant with the Italian Laws.
* user interface supports common browsers as well as mobile phone web browsers
* password recovery via mobile phone or email
* per user traffic monitoring
* user monitoring and administration via dedicated admin interface
* admin interface supports role based administration (operator, admin, superadmin)
* via the admin interface an operator can add new users, modify users' information, enable/disable users, monitor traffic/user nationality/logins/registrations
* english/italian translation

Even though the application can be used as standalone, such use will result in a pretty useless application. OpenWISP User Management System is in fact made to be integrated with RADIUS authentication, authorization and accounting features.

When working together a RADIUS implementation, OWUMS becomes a natural back-end to a WISP's user-related functionalities. Users who successfully register  and verify themselves via OWUMS are also considered valid RADIUS users (support for RADIUS user groups is on its way).
OWUMS is being developed to use FreeRADIUS 2.1 (http://freeradius.org/), so other RADIUS implementations are currently not supported.

## How to install

### Prerequisites

The OpenWISP User Management System is currently being developed with Ruby on Rails 3.0.20. Being a RoR application, it can be
deployed using any of the methods Rails supports.
Even so, what we are currently using (and find quite stable) is the following environment:

* Ruby Enterprise Edition 1.8 (http://www.rubyenterpriseedition.com/index.html)
* Apache 2.2 (http://www.apache.org/)
* Phusion Passenger 2.2 or 3.0 (http://www.modrails.com/index.html)
* MySQL 5.1 (http://dev.mysql.com/downloads/mysql/)
* FreeRADIUS 2.1 (http://freeradius.org/download.html)
* festival (http://www.cstr.ed.ac.uk/projects/festival/) and festival italian 'localization' packages (http://www.pd.istc.cnr.it/TTS/ItalianFESTIVAL) (for captcha accessibility)
* A SIP capable media-gateway like Asterisk (http://www.asterisk.org/) or the Patton Smart Node with or without a sip proxy/router (like OpenSIPs)

### Installation

Once deployed using your favourite environment, you need to configure two deamons OpenWISP User Management System needs to perform its usual activities (mainly managing incoming phone calls and deleting users when the registration procedure times out).

To do this, you can use the following init.d script (customization may be needed, this script was coded for Ubuntu 10.04).

Be sure the cache folder is writable:

    chown -R www-data:www-data tmp/cache/

#### Startup script

The following script (Ubuntu/Debian style) should be named owums-daemons. It assumes OpenWISP User Management Systemis running on ruby enterprise and that the application was deployed to /var/rails/owums.
Of course you can change any of that to whatever fits your needs.


    #!/bin/sh
    ### BEGIN INIT INFO
    # Provides:          owums-daemons
    # Required-Start:    $local_fs $network
    # Required-Stop:     $local_fs $network
    # Default-Start:     2 3 4 5
    # Default-Stop:      0 1 6
    # Short-Description: Starting owums-daemons
    # Description:       Starting owums-daemons
    ### END INIT INFO#

    ########## Variables for openwisp-daemons ##########

    # The directory in which all the various OpenWisp
    # applications are deployed. Generally it's /var/www
    # or /var/rails
    OPENWISP_BASE_PATH="/var/rails"

    # The daemon you wish to start with this script
    # (it must have already been deployed of course).
    OPENWISP_APP="owums"

    # The Rails environment in which the script must be run.
    # It will almost always be set to production.
    RAILS_ENV="production"

    ####################################################

    export PATH RAILS_ENV

    # Define LSB log_* functions.
    # Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
    . /lib/lsb/init-functions

    bundle_exec() {
      cd $1 && bundle exec $2
      return $?
    }

    openwisp_daemons_start() {
      bundle_exec $OPENWISP_BASE_PATH/$OPENWISP_APP 'rake daemons:start'
    }

    openwisp_daemons_stop() {
      bundle_exec $OPENWISP_BASE_PATH/$OPENWISP_APP 'rake daemons:stop'
    }

    openwisp_daemons_restart() {
      bundle_exec $OPENWISP_BASE_PATH/$OPENWISP_APP 'rake daemons:restart'
    }

    openwisp_daemons_status() {
      bundle_exec $OPENWISP_BASE_PATH/$OPENWISP_APP 'rake daemons:status'
    }

    case "$1" in
      start)
        log_daemon_msg "Starting OpenWISP daemon" "$NAME"
        openwisp_daemons_start
        RET="$?"
        log_end_msg $RET
        return $RET
        ;;
      stop)
        log_daemon_msg "Stopping OpenWISP daemon" "$NAME"
        openwisp_daemons_stop
        RET="$?"
        log_end_msg $RET
        return $RET
        ;;
      restart)
        log_daemon_msg "Restarting OpenWISP daemon" "$NAME"
        openwisp_daemons_restart
        RET="$?"
        log_end_msg $RET
        return $RET
        ;;
      status)
        openwisp_daemons_status
        RET="$?"
        return $RET
        ;;
      *)
        echo "Usage: /etc/init.d/$NAME {start|stop|restart|status}" >&2
        exit 1
        ;;
    esac

    exit 0

As usual, you need to

    chmod +x owums-daemons
    /etc/init.d/owums-daemons start

and enable the script to be run at boot (_e.g._: with the @update-rc.d@ command).

#### Logs rotation

To enable the rotation of logs it is possible to use following @logrotate@ script (it could be saved as /etc/logrotate.d/rails).

    /var/rails/*/log/*.log {
        weekly
        missingok
        rotate 52
        compress
        delaycompress
        notifempty
        copytruncate
    ## It's possible to use the following macros instead of the "copytruncate" option
    #   create 660 root www-data
    #   sharedscripts
    #  postrotate
    #    if [ -f "`. /etc/apache2/envvars ; echo ${APACHE_PID_FILE:-/var/run/apache2.pid}`" ]; then
    #      /etc/init.d/apache2 reload > /dev/null
    #    fi
    #    /etc/init.d/owums-daemons restart
    #  endscript
    }

#### Media gateway OR SIP proxy/router configuration

The final step is to configure the telephone number your users will use to register themselves.
You'll have to create a "static routing" between a PSTN number and OpenWISP User Management Systemvoip client (which is called "sip busy machine").

There are many ways for doing this (see below). in every case you'll need to configure the OpenWISP User Management Systemas follow (I'm assuming you're running OpenWISP User Management Systemin production environment):

    ~# <owums root>/script/console production
    Loading production environment (Rails 3.0.20)
    >> Configuration.set("verification_numbers", "<TELEPHONE NUMBER>")
    >> Configuration.set("sip_listen_address","0.0.0.0")
    >> Configuration.set("sip_servers", "<SIP MEDIAGATWAY/PROXY/SERVER IP ADDRESS>")

With OWUMS' current version, instead of using the console, you can also change OWUMS' configuration keys from the admin Operator panel (with url operator/login).

Then restart OpenWISP User Management Systemsip busy machine (for instance with the supplied init.d script)

Now a media gateway or a SIP proxy/router should be properly configured.
There are many different softwares or appliances that will do the job. Here follows some examples:

##### Configuring a Patton Smart Node

A configuration example for the Patton Smart Node is the following:

    context cs switch

    [...]

     routing-table called-e164 from_pstn_rtable
       route [...]
       route <TELEPHONE NUMBER> dest-interface OWUMS

    [...]

     interface sip OWUMS
       bind gateway sip_gw
       route call dest-table drop_rtable
       remote <OWUMS server IP address>

    [...]

    gateway sip sip_gw
     bind interface LAN router

    [...]

##### Configuring OpenSIPs

If you have a working sip proxy/router like Opensips, it's sufficient to add a permanent _user location_ like so:

    opensipsctl ul add <TELEPHONE NUMBER OR SUFFIX> <OWUMS SIP URI>

For instance, assuming owums is running on the host with IP address 192.168.100.100

    opensipctl ul add 123 sip:123@192.168.100.100

##### Configuring SipX

Another sip proxy/router could be SipX. In this case you have to configure something more. We'll use an ITSP phone number, so (i'm assuming you're running a working installation of Sipx) in Devices -> Gateway add a new Sip Trunk and fill:

Name, choose a template or insert the ITSP Address then apply
In ITSP Account -> Username and Password

Now Send Profile and restart the related Services, check the registration status in Diagnostic -> Internal SBC Statistics. Create a New User with the ITSP phone number as User ID (to enable DID) and add a new rule in Call Forwarding to forward after 1 second all incoming calls to "ITSPnum@owumsIP". Uncheck the Voice Mail box in Permissions.

##### Configuring Audiocodes Mediant 1000

Using the GUI:
* Go to "Configuration" -> "Protocol Configuration" -> "Routing Table"  and select "Tel to IP routing"
* Insert a new route with appropriate values (destination phone prefix, destination IP address, etc.)

### Configure FreeRADIUS to work with OWUMS

Create the freeradius DBMS users and set the appropriate privileges. For instance, if you're using MySQL:

    GRANT USAGE ON *.* TO 'radius'@'localhost' IDENTIFIED BY '<MyPasswordIsBetterThanYours>';
    GRANT SELECT ON `<OWUMS DB name>`.`radreply` TO 'radius'@'localhost'
    GRANT SELECT ON `<OWUMS DB name>`.`radgroupcheck` TO 'radius'@'localhost'
    GRANT SELECT ON `<OWUMS DB name>`.`radcheck` TO 'radius'@'localhost'
    GRANT SELECT ON `<OWUMS DB name>`.`radgroupreply` TO 'radius'@'localhost'
    GRANT SELECT, INSERT, UPDATE ON `<OWUMS DB name>`.`radacct` TO 'radius'@'localhost'
    GRANT SELECT ON `<OWUMS DB name>`.`radusergroup` TO 'radius'@'localhost'
    GRANT SELECT ON `<OWUMS DB name>`.`dictionary` TO 'radius'@'localhost'
    GRANT SELECT ON `<OWUMS DB name>`.`nas` TO 'radius'@'localhost'

where:
* <MyPasswordIsBetterThanYours> is the radius user password. Should be different from the one used for the RoR application
* <OWUMS DB name> is the DB name used for the RoR application

Configure freeradius to use the OpenWISP User Management System DB, editing the sql.conf file as described here: http://wiki.freeradius.org/SQL_HOWTO

For instance, if you're using MySQL:

    sql {
        database = "mysql"
        driver = "rlm_sql_${database}"

        server = "localhost"
        port = 3306
        login = "radius"
        password = "<MyPasswordIsBetterThanYours>"
        radius_db = "<DBMS name>"
    [...]

## Rails App Configuration

The behaviour of some features can be tweaked, some instructions on the most important features follows.

### Simplify the Registration Form

By default, all the fields of the user profile are mandatory, however, in order to simplify and speed up the user registration procedure it is possible to change this behaviour and hide the following fields:

* birth date
* address
* city
* postal code
* state

To do that proceed by copying the file **config/config.default.yml** and rename it to **config/config.yml**, then set to **false** the fields you want to disable and hide.
This change requires OWUMS to be restarted by reloading the web server and backgroundrb.

If the file **config/config.yml** does not exist, OWUMS will read the default values from **config/config.default.yml** (so do not delete it).

### Disable Captcha in the Registration Form

If you need to disable the Captcha field in the registration form you can do it by going into OWUMS's admin web interface to **configurations/**, look for **captcha_enabled** and set it to **false**.

### User notifications

Users are notified / emailed in two occasions:

1. <b>New account notification</b>: when they register and verify their new account
2. <b>Password reset</b>: when they reset their password

This means that the SMTP server must be configured correctly otherwise the owums will not work properly.

### Experimental features configurable in config/config.yml

**automatic_captive_portal_login**

**default**: true

Attempts to login users automatically after they confirm their account. Depends on OWCPM auth_api branch.
Configuration key (found in the web interface at /configurations) "captive_portal_baseurl" must be filled correctly (base url of the OWCPM instance).

**mac_address_authentication**

**default**: false

Enable mac address authentication as "verification_method" for users.

### New account notification

This feature might be disabled by setting **send_email_notification_to_users** to "false" in **config/config.yml**.

If you want to customize this behaviour the configuration keys to look for are:

* account_notification_message_en
* account_notification_message_it
* account_notification_subject_en
* account_notification_subject_it

### Password reset

If you want to customize this behaviour the configuration keys to look for are:

* password_reset_from
* password_reset_instructions_custom

TODO: change **password_reset_from** into **email_from**

### Radius Accounting API Usage

Retrieve information about radius sessions through a simple HTTP API.

<b>Requires authentication as an operator</b> (HTTP Basic auth or Session Based, it is highly suggested to use over SSL).

#### All sessions:

Retrieve information of all latest sessions.

<b>HTTP method</b>: GET

**XML**: /radius_accountings.xml

**JSON**: /radius_accountings.json

<b>Accepted querystring parameters (filters)</b>:

* **day**: filter records of specified date (string in "YYYY-MM-DD" format)
* **last**: limit records to specified number
* **ap**: filter records which contain mac address of specified AP in CalledStationId column

#### User related sessions:

Retrieve information of latest sessions of a specified user.

<b>HTTP method</b>: GET

**XML**: /users/:user_id/radius_accountings.xml

**JSON**: /users/:user_id/radius_accountings.json

<b>Accepted querystring parameters (filters)</b>:

Same filters of "All sessions".

### OWMW Integration

OWMW might be used to retrieve the mac address of the access point from which users connected.

To enable OWMW, copy and rename the file **config/owmw.yml.example** in **config/owmw.yml**, then set the correct values for "url", "username" and "password".

### Rake task radius_accountings:convert

A rake task is available to convert called station id values which are not aware from which the users connected.

<b>This task depends on OWMW 0.0.7</b>.

    rake radius_accountings:convert

It will convert the CalledStationId of the records of online users which do not
contain the mac address of the access point from which they connected to the following format:

    <uppercase_dashed_access_point_mac_address>:<original_called_station_id>

eg:

    10-40-F3-7E-56-B8:pfsense

This rake task can be run periodically or can be triggered by radius each time a user authenticates.

If you need to run it periodically you can uncomment the following lines in the
file **config/backgroundrb.yml**:

    #:convert_radius_accountings:
    #  :trigger_args: 0  *  * * * * *

This functionality is used in OpenWISP Geographic Monitoring to show
the 10 latest logins of each access point.

### Rake task radius_accountings:cleanup_stale

In some extreme cases you might need to cleanup stale radius sessions which do not have an AcctStopTime set.

invoke this rake task this way:

    radius_accountings:cleanup_stale

or:

    RAILS_ENV=production bundle exec rake radius_accountings:cleanup_stale

#### What does this task do?

* it will try to recalculate the AcctStopTime for those sessions which have an AcctSessionTime greater than 0, in this case the AcctTerminateCause will be set to **OWUMS-Stale-Recalculated**
* if AcctSessionTime is 0 it will set AcctStopTime to the same value as AcctStartTime and will set AcctTerminateCause to **OWUMS-Stale-Invalid**

At the end of the operation the task will output the results indicating how many sessions have been recalculated and how many have been marked as invalid.

### Languages

By default, english, italian and spanish are active.

You can disable them by editing: **config/config.yml**.

    english: true
    italian: false
    spanish: true

### Credit Card verification method

For this subject see the file **Gestpay-instructions.rdoc**.

### Social login verification method

Two authentication providers supported:

 * Facebook
 * Google+

The behaviour can be configured by editing the following configuration keys:

* **social_login_enabled**: `true` or `false`, defaults to `false`
* **social_login_facebook_id**: facebook app id
* **social_login_facebook_secret**: facebook app secret key
* **social_login_google_id**: google+ app id
* **social_login_google_secret**: google+ app secret key
* **social_login_success_url**: the URL where the user will be redirected after logging in correctly, if empty the user will be redirected to his/her account page
* **social_login_ask_mobile_phone**: this config key may have 3 possible values (defaults to `unverified`):
  * `never`: will never ask mobile phone number to users
  * `unverified`: will ask only to unverified users (valid for facebook only, google+ will always be always treated as unverified)
  * `always`: will always ask mobile phone number to users

If when logging in you get the following error: `failed_to_connect`, you will have to adjust the `ssl_ca_path` setting in your `config/config.yml` file.

Find out where ssl certificates are stored with `openssl version -a | grep OPENSSLDIR`.

### Sentry exception notification

**Available since OWUMS 1.4.**

Just add to your configuration file in `config/config.yml` the following line:

    sentry_dsn: 'http://public:secret@example.com/project-id'

To obtain a new `dsn` setting key, create a new project in your sentry account, add the domain of the OWUMS instance on to the allowed domains, then get the dsn setting by going to the "installation & setup" page on the project.

## Notice

The OWUMS uses the Highcharts library.
This library is released under a Creative Commons Attribution-NonCommercial 3.0 License (http://creativecommons.org/licenses/by-nc/3.0/)

For further informations, please refer to the Highsoft Solutions AS website (http://www.highcharts.com/license)

Public Administrations or other no-profit organizations that use this software to give a free WiFi Network service to their users should refer to the "Non-commercial - Free" section.
Other entities must refer to the "Commercial" section.

## Copyright

Copyright (C) 2015 OpenWISP.org

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
