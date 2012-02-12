#!/usr/bin/perl -w

#########################################################################
#
#    Encrypt email script for maildrop
#
#    version: 0.1
#
#    Release date: Feb 12, 2012
#
#########################################################################
#
#    AUTHOR:
#    Salahuddin <salahuddin@qomento.com>
#
#    COPYRIGHT AND LICENSE:
#
#    Copyright (C) 2012, Salahuddin.
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
##########################################################################
#
#   Usage:
#
#   This script simply encrypt (using gnupg) the incomming emails based 
#   on the $GPGKEY.
#
#   Example configuration of ~/.mailfilter
#   -----------------------------------------------------------------------
#   DEFAULT="$HOME/Maildir"
#   SHELL="/bin/bash"
#
#   if (!/^Content-Type: multipart\/encrypted/ || !/protocol\=\"application\/pgp\-encrypted\"/)
#   {
#	xfilter "~/gnupg_maildrop.pl | reformail -I 'Content-Type: multipart/encrypted; protocol=\"application/pgp-encrypted\"; boundary=\"MfFXiAuoTsnnDAfX\"' -I 'Content-transfer-encoding:' -I 'Content-disposition:'"
#   }
#
#   -----------------------------------------------------------------------
#
###########################################################################
#
#  This script is based on procmail example from:
#
#  http://www.torservers.net/wiki/setup/mailserver?rev=1315171637
#  http://www.j3e.de/pgp-mime-encrypt-in-procmail.html
#
###########################################################################

use strict;

my $GPGKEY = "00000000";

my $mail_header = "";
my $mail_body = "";
my $old_header = "";

# mail_header pending
my $status = 0;      

my $gpg_header = '--MfFXiAuoTsnnDAfX
Content-Type: application/pgp-encrypted
Content-Disposition: attachment

Version: 1

--MfFXiAuoTsnnDAfX
Content-Type: application/octet-stream
Content-Disposition: inline; filename="msg.asc"

~

';

my $gpg_end = '

--MfFXiAuoTsnnDAfX

';


# read from stdin
while(<STDIN>)  {    
    if($status == 0) {
	append_mail_header($_);
	#first empty line found
	if ($_ =~ /^$/) {
	    $status = 1; # stop reading the header
	}
    }
    else {
	append_mail_body($_);
    }
}

# escape "
$mail_header =~ s/"/\\"/gi;
$mail_body =~ s/"/\\"/gi;

# get old header - Content-type and a line gap
my $old_header_command = "echo \"" . $mail_header . "\" | reformail -XContent-Type: -XContent-disposition: -XContent-transfer-encoding:; echo ;";
$old_header = qx($old_header_command);

# escape "
$old_header =~ s/"/\\"/gi;

# add old-header with body
$mail_body = $old_header . $mail_body;


# encrypt the body with gpg
my $gpg_comamnd = "echo \"" . $mail_body . "\" | gpg --batch --quiet --always-trust -a -e -r " . $GPGKEY;
my $encrypted_mail_body = qx($gpg_comamnd);

# output
print  $mail_header . $gpg_header . $encrypted_mail_body . $gpg_end;


sub append_mail_header {
    $mail_header = $mail_header . $_[0];
}

sub append_mail_body {
    $mail_body = $mail_body . $_[0];
}
