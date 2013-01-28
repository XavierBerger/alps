package Page;

my $verbose=0;

use strict;
use POSIX;
use Sqlite;

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


sub AddTab {
  my $this = shift;
  my $tabId = shift;

  $this->Debug(4,"");

  my $content;
  my $sqlite = $this->{'alps'}->{'sqlite'};
  my $query = "SELECT * FROM component WHERE idtab=$tabId ORDER BY ord";
  my $response = $sqlite->ExecuteQuery($query);
  my $componentPanel="";
  foreach my $row (@$response) {
     my ($idsys, $name , $ord, $idtab,$comment) = @$row;
     #$componentPanel .= "\n          <li><a href=\"#tabs-$idsys\">$name</a></li>";
     $componentPanel .= $this->AddComponent($idsys,$name,$comment);
  }
  $content .= "
      <div class='ui-state-default ui-corner-all addcomponent'>
        <span class='ui-icon ui-icon-plus'></span>
      </div>
      <div class='ui-state-default ui-corner-all edittab' id='edittab-$tabId'>
        <span class='ui-icon ui-icon-pencil'></span>
      </div>
      <div class='ui-state-default ui-corner-all deletetab'>
        <span class='ui-icon ui-icon-close'></span>
      </div>
      <br>
      <div class='tabpanel'>
        <ul id='componentlist-$tabId' class='componentlist'>$componentPanel
        </ul>
      </div>
  ";

  ($tabId >= 0) and return "\n    <div id='tabs-$tabId'>$content  </div>";
  return $content;
}

sub AddShortcut
{
  my $this=shift;
  $this->Debug(4,"");
  my $idsys = shift;
  my $name = shift;
  my $link = shift;
  return "<li class='toto'><a href='$link'>$name</a></li>";
}

sub AddComponent
{
  my $this=shift;
  $this->Debug(4,"");
  my $idsys = shift;
  my $name = shift;
  my $comment = shift;
  my $sqlite = $this->{'alps'}->{'sqlite'};

  my $content = "
            <li class='ui-state-default componentlistli' id='componentPanel-$idsys'>
              <div class='componenttitle' id='componenttitle-$idsys'><b>$name</b></div>
              <div class='ui-state-default ui-corner-all addshortcut' id='addshortcut-$idsys'>
                <span class='ui-icon ui-icon-plus'></span>
              </div>
              <div class='ui-state-default ui-corner-all editcomponent' id='editcomponent-$idsys'>
                <span class='ui-icon ui-icon-pencil'></span>
              </div>
              <div class='ui-state-default ui-corner-all deletecomponent' id='deletecomponent-$idsys'>
                <span class='ui-icon ui-icon-close'></span>
              </div>
              <br>
              <div>
                COMMENTS
              </div>
              <ul class='sortable' id='componentPanelList-$idsys' style='position: relative; top: -60px;'>";
  my $query = "SELECT * FROM shortcut WHERE idcomponent=$idsys";
  my $response = $sqlite->ExecuteQuery($query);
  foreach my $row (@$response) {
     my ($idsys, $name, $idcomponent, $command) = @$row;
     $content .= $this->AddShortcut($idsys, $name, $command);
  }
  $content .= "</ul></li>";
  $content =~ s/\n//g;
  return $content;
}

sub HtmlDeleteDialog
{
  my $this=shift;
  my $id = shift;
  my $element = shift;

  $this->Debug(4,"");

  return qq[
  <!-- Dialog comfirm delete $element-->
  <div class="dialog-confirm" id='$id' title="Delete the current $element?">
    <p>
      <span class="ui-icon ui-icon-alert" style="float:left; margin:0 7px 20px 0;"></span>
      These $element will be permanently deleted and cannot be recovered. Are you sure?
    </p>
  </div>
  ];

}

sub Print
{
  my $this=shift;
  $this->Debug(3,"");
  my $sqlite = $this->{'alps'}->{'sqlite'};

  my $content = q[<!DOCTYPE html>
<html>
<head>
  <title>Administrator's Landing Page Shortcuts</title>
];
    foreach (@{$this->{'alps'}->{'paths'}}) {
      /\.css$/ and $content .= "  <link rel=\"stylesheet\" href=\"$_\" />\n";
      /\.js$/  and $content .= "  <script type=\"text/javascript\" src=\"$_\"></script>\n"
    }
    $content .= q [
</head>
<body>
  ].
  $this->HtmlDeleteDialog("deletetab", "tab").
  $this->HtmlDeleteDialog("deletecomponent", "component").
  q[

  <!-- Dialog addtab -->
  <div id="addtab" title="New tab">
    <form>
      <fieldset class="ui-helper-reset">
      <label for="addtab_title">Tab Name</label>
      <input type="text" name="addtab_title" id="addtab_title" value="" class="ui-widget-content ui-corner-all" />
      </fieldset>
    </form>
  </div>

  <!-- Dialog edittab -->
  <div id="edittab" title="Edit tab">
    <form>
      <fieldset class="ui-helper-reset">
      <label for="edittab_title">Tab Name</label>
      <input type="text" name="edittab_title" id="edittab_title" value="" class="ui-widget-content ui-corner-all" />
      </fieldset>
    </form>
  </div>

  <!-- Dialog addcomponent -->
  <div id="addcomponent" title="Add component">
    <form>
      <fieldset class="ui-helper-reset">
      <label for="component_name">Component name</label>
      <input type="text" name="component_name" id="component_name" value="" class="ui-widget-content ui-corner-all" /><br>
      <!--label for="component_comment">Comments</label><br-->
      <!--textarea name="component_comment" id="component_comment">test</textarea-->
      <!--textarea name="component_comment" id="component_comment" value="" class="ui-widget-content ui-corner-all"></textarea-->
      </fieldset>
    </form>
  </div>

  <!-- Dialog editcomponent -->
  <div id="editcomponent" title="Edit component">
    <form>
      <fieldset class="ui-helper-reset">
      <label for="editcomponent_name">Component name</label>
      <input type="text" name="editcomponent_name" id="editcomponent_name" value="" class="ui-widget-content ui-corner-all" /><br>
      <label for="component_comment">Shortcut list</label><br>
      </fieldset>
    </form>
  </div>

  <!-- Dialog addshortcut -->
  <div id="addshortcut" title="Add shortcut">
    <form>
      <fieldset class="ui-helper-reset">
      <label for="shortcut_name">Shortcut name</label>
      <input type="text" name="shortcut_name" id="shortcut_name" value="" class="ui-widget-content ui-corner-all" /><br>
      <label for="shortcut_command">Command</label>
      <input type="text" name="shortcut_command" id="shortcut_command" value="" class="ui-widget-content ui-corner-all" /><br>
      </fieldset>
    </form>
  </div>

  <!--Dialog Help-->
  <div id="help" title="Help">
    <h3>Administator's Landing Page Shortcuts</h3>
    <h4>Introduction</h4>
    <p>This tool is designed for administrator that manage numerous server and needs a
    centralized fast access to each machines.
    With ALPS you will easily create a landing page with all the shorcuts you use every days.
    This shortcut can be ssh (including remote command), telnet, rdp links etc.</p>
    <h4>Usage</h4>
    If you reach this point, congratulation, it means that you already install the web server properly.
    After reading this introduction, you can close it and add a new tab by clicking on the + on top of this page.
    Then click on the button to add a new component reachable from an ip address.
    <h4>Credit</h4>
    Developer: X@v | Tools: perl, sqlite, jquery, json | Background picture: <a href="http://www.flickr.com/photos/lassi_kurkijarvi/4547648205/sizes/o/in/photostream/">Lassi Kurkijarvi</a>
  </div>

  <!--Toolbar-->
  <div class="ui-state-default ui-corner-all power">
    <a onclick="javascript: $.post( 'Close');" href="#"><span class="ui-icon ui-icon-power"></span></a>
  </div>
  <div class="ui-state-default ui-corner-all help">
    <a id="helplink"><span class="ui-icon ui-icon-help"></span></a>
  </div>
  <div class="ui-state-default ui-corner-all options">
    <a id="options"><span class="ui-icon ui-icon-wrench"></span></a>
  </div>

  <!--Title-->
  <div class="title">
    <span class="title">A</span>dministator's
    <span class="title">L</span>anding
    <span class="title">P</span>age
    <span class="title">S</span>hortcuts
  </div>

  <!--Tabs-->
  <div id="tabs" >
    <ul id="tabs-ul">
];
      my $query = "SELECT * FROM tab ORDER BY ord";
      my $response = $sqlite->ExecuteQuery($query);
      my $tab="";
      foreach my $row (@$response) {
         my ($idsys,$name, $ord) = @$row;
         $content .= "      <li><a href=\"#tabs-$idsys\">$name</a></li>\n";
         $tab .= $this->AddTab($idsys);
      }
      $content .= qq[    </ul>$tab
  </div>

  <!--Footer-->
  <div class="smallline">
    <div class="title">
      <sup>
        Copyright &copy; Xavier Berger - License GPLv3 -
        <a class="smallline" href="http://code.google.com/p/alps/">
          http://code.google.com/p/alps/
        </a>
      </sup>
    </div>
  </div>

  </body>
</html>
];

  return $content;
}


1;
