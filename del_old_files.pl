
use strict;

sub help()
{
  print "del_old_files.pl <dir> <mask> <age>\n";
  print "Delete from specified DIR files with specified MASK than older then AGE days.\n\n";
}

sub del_tree
{
my $dir = shift;

}

sub delete_old_files
{
my $dir = shift;
my $mask = shift;
my $age = shift;
my $CurUnixTime = time();
my $MaxDiff = 3600 * 24 * $age;

my $elem;
my @files_and_dirs;
my $path;
my $mtime;
my $TimeDiff;

  #print "MaxDiff: $MaxDiff\n";

  # *.txt	-> 	(.*?)\.txt
  # *.tx*	->	(.*?)\.tx(.*?)
  $mask =~ s/\./\\\./g;			#change of point
  $mask =~ s/\*/\(\.\*\?\)/g;		#change of *
  $mask = "^" . $mask . "\$";		#beginning and end of string


  #get content of directory
  opendir(DIR, $dir);
  @files_and_dirs = readdir(DIR);
  closedir(DIR);

  #exclude . and ..
  foreach $elem(@files_and_dirs) {
    next if ($elem eq ".");
    next if ($elem eq "..");
    next if ($elem !~ /$mask/);
    $path = $dir . "/" . $elem;
    $mtime = (stat($path))[9];
    $TimeDiff = abs($mtime - $CurUnixTime);
    if ($TimeDiff > $MaxDiff) {
      #file or directory too old
      if (-d $path) {
        #directory
        #print "delete old directory $path\n";
      }
      else {
        #file
        #print "delete old file $path\n";
        unlink($path);
     }
    }
  }
}

#-----------------------------------main----------------------------------
if ($#ARGV != 2) {
  help();
  exit(0);
}
delete_old_files($ARGV[0], $ARGV[1], $ARGV[2]);
