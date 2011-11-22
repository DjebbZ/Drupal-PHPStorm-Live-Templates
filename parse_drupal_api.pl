#!/usr/bin/perl

# Copyright (C) 2011  Jeremie Le Hen <jeremie@le-hen.org>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#
# How to run this script:
# $ cd /path/to/drupal
# $ find . -name \*.php | xargs grep -l '^function hook_' | \
#    xargs /path/to/parse_drupal_api.pl > ~/.WebIde10/config/templates/user.xml

use strict;
use warnings;

my @comment;
my @function;

my $DEFAULT = 0;
my $IN_COMMENT = 1;
my $IN_FUNCTION = 2;

my $state = $DEFAULT;

print <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<templateSet group="user">
EOF
while (<>) {
    chomp;
    if (m,^\/\*\*,) {
        @comment = ();
        push @comment, $_;
        $state = $IN_COMMENT;
        next;
    }
    if (m,^function hook_,) {
        @function = ();
        push @function, $_;
        $state = $IN_FUNCTION;
        next;
    }
    if ($state == $IN_COMMENT) {
        push @comment, $_;
        if (m,^ \*\/,) { $state = $DEFAULT }
        next;
    }
    if ($state != $IN_FUNCTION) { next }

    # $state == $IN_FUNCTION
    push @function, $_;
    if (not m,^\}$,) { next }

    # $_ eq "}"
    my $end;

    $function[0] =~ m/function hook_(\w+)/;
    my $xml_longname = "hook_".$1;
    my $xml_shortname = "h_".$1;
    $function[0] =~ s/function hook_/function \$MODULE_NAME\$_/;
    $end = pop @function;
    push @function, '  $END$', $end;

    pop @comment;
    shift @comment;
    push @comment, ' *';
    my @comment_begin = ('/**', " * Implements $xml_longname().", " *");
    my @comment_end = (' * $COMMENT$', ' */');

    # From now on, build XML
    my $xml_longvalue = join ("\n", @comment_begin, @comment, @comment_end, @function);
    my $xml_shortvalue = join ("\n", @comment_begin, @comment_end, @function);
    foreach (\$xml_longvalue, \$xml_shortvalue) {
        $$_ =~ s/&/&amp;/g;
        $$_ =~ s/"/&#34;/g;
        $$_ =~ s/'/&#39;/g;
        $$_ =~ s/</&#60;/g;
        $$_ =~ s/>/&#62;/g;
        $$_ =~ s/\n/&#10;/g;
    }
    print <<EOF;
  <template name="$xml_longname" value="$xml_longvalue" description="$xml_longname" toReformat="false" toShortenFQNames="true">
    <variable name="COMMENT" expression="" defaultValue="" alwaysStopAt="true" />
    <variable name="MODULE_NAME" expression="" defaultValue="" alwaysStopAt="true" />
    <context>
      <option name="HTML_TEXT" value="false" />
      <option name="HTML" value="false" />
      <option name="XSL_TEXT" value="false" />
      <option name="XML" value="false" />
      <option name="CSS" value="false" />
      <option name="JAVA_SCRIPT" value="false" />
      <option name="JSP" value="false" />
      <option name="SQL" value="false" />
      <option name="PHP" value="true" />
      <option name="OTHER" value="false" />
    </context>
  </template>
  <template name="$xml_shortname" value="$xml_shortvalue" description="$xml_longname" toReformat="false" toShortenFQNames="true">
    <variable name="COMMENT" expression="" defaultValue="" alwaysStopAt="true" />
    <variable name="MODULE_NAME" expression="" defaultValue="" alwaysStopAt="true" />
    <context>
      <option name="HTML_TEXT" value="false" />
      <option name="HTML" value="false" />
      <option name="XSL_TEXT" value="false" />
      <option name="XML" value="false" />
      <option name="CSS" value="false" />
      <option name="JAVA_SCRIPT" value="false" />
      <option name="JSP" value="false" />
      <option name="SQL" value="false" />
      <option name="PHP" value="true" />
      <option name="OTHER" value="false" />
    </context>
  </template>
EOF
}
print <<EOF;
</templateSet>
EOF
