

my $verbose = 0;

package Css;
use strict;
use POSIX;
use CGI::Session;


sub new
{
  my $this = bless {}, shift;
  $this->{'alps'} = shift;
  $verbose = $this->{'alps'}->{'verbose'};

  $this->Debug(3,"");

  return $this;
}

sub Debug
{
  my $this = shift;
  my $level = shift;

  $level <= $verbose or return;
  print STDERR "[", strftime("%Y/%m/%d-%H:%M:%S", localtime), "] ", " " x $level, (caller 1)[3], " @_\n";
}

sub Print {
  my $this = shift;
  $this->Debug(3,"");

  my $session = $this->{'alps'}->{'session'};
  my $componentWidth=$session->param('componentWidth') || 310;
  my $componentHeight=$session->param('componentHeight') || 150;
  my $componentButtonOffset=$session->param('componentButtonOffset') || 92;

  return "
    body {
      font-family:\"Times New Roman\";
      font-size:10px;
      background-image:url('/css/background.jpg');
      background-repeat:no-repeat;
      background-size: 100%;
    }
    div.help {
      z-index:99;
      position: absolute;
      top: 5px;
      right: 10px;
      background-color:#FFFFFF;
      cursor: pointer;
    }
    div.options {
      z-index:99;
      position: absolute;
      top: 5px;
      right: 30px;
      background-color:#FFFFFF;
      cursor: pointer;
    }
    div.power {
      z-index:99;
      position: absolute;
      top: 5px;
      right: 50px;
      background-color:#FFFFFF;
      cursor: pointer;
    }

    #tabs div .deletetab {
      z-index:99;
      position: absolute;
      top: 37px;
      right: 4px;
      background-color:#FFFFFF;
      cursor: pointer;
    }
    #tabs div .edittab {
      z-index:99;
      position: absolute;
      top: 37px;
      right: 24px;
      background-color:#FFFFFF;
      cursor: pointer;
    }
    #tabs div .addcomponent {
      z-index:99;
      position: absolute;
      top: 37px;
      right: 45px;
      background-color:#FFFFFF;
      cursor: pointer;
    }
    div .componenttitle {
      z-index:99;
      position: relative;
      top: 2px;
      left: 2px;
      height: 16px;
      vertical-align:top;
    }
    div .addshortcut {
      z-index:99;
      position: relative;
      top: -14px;
      left: ".($componentWidth-58)."px;
      width: 16px;
      background-color:#FFFFFF;
      cursor: pointer;

    }
    div .editcomponent {
      z-index:99;
      position: relative;
      top: -32px;
      left: ".($componentWidth-38)."px;
      width: 16px;
      background-color:#FFFFFF;
      cursor: pointer;
    }
    div .deletecomponent {
      z-index:99;
      position: relative;
      top: -50px;
      left: ".($componentWidth-18)."px;
      width: 16px;
      background-color:#FFFFFF;
      cursor: pointer;
    }
    div.title {
      text-align:center;
      color:#554433;
    }
    span.title {
      font-size:15px;
      color:#334455;
    }
    div.smallline {
      text-align:center;
    }
    a.smallline{
      text-decoration:none;
      color:#334455;
    }

    div.tabpanel {
      margin: 0px 3px 3px 3px;
      width: 100%;
      overflow: hidden;

    }

    .componentlist {
      list-style-type: none;
      margin: 0;
      padding: 0;
    }

    .componentlistli {
      margin: 4px 4px 0px 0;
      padding: 1px;
      float: left;
      width: ".($componentWidth)."px;
      height: ".($componentHeight)."px;
    }


    .shortcutList {
      list-style-type: none;
      margin: 0;
      padding: 0;
      width: 54em;
    }
    .shortcutList li {
      //margin: 0 3px 3px 3px;
      padding: 0.2em;
      padding-left: 1.5em;
      height: 17px;
    }

    .shortcutList li .move {
      position: absolute;
      margin-left: -1.3em;
    }

    .shortcutList li input {
      width: 25em;
    }

    .shortcutList li .close {
      position: absolute;
      margin-top: -1.5em;
      margin-left: 50.75em;
    }

    .ui-state-highlight {
      height: 1.5em;
      line-height: 1.2em;
    }
   ";

}


1;
