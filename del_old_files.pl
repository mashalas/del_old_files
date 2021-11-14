
use strict;
#use Time::Local 'timelocal';

my $sn = 0;
my $par__dir = $sn; $sn++;
my $par__mask = $sn; $sn++;
my $par__mask__raw = $sn; $sn++;
my $par__age = $sn; $sn++;
my $par__age__raw = $sn; $sn++;
my $par__verbose = $sn; $sn++;
my $par__recursive = $sn; $sn++;
my $par__help = $sn; $sn++;
my $par__parse_errors = $sn; $sn++;
my $par__dry_run = $sn; $sn++;
my $par__newer = $sn; $sn++;
my $SLASH;
my $ERROR_MESSAGES_DIVIDER = "|";

sub help()
{
  print "del_old_files.pl [-v|--verbose] [-r|--recursive] [-d|--dry-run] [-n|--newer] <dir> <mask> <age[measure]>\n";
  print "Delete from specified DIR files with specified MASK than older then AGE.\n";
  print "Allowed measures for AGE: s=seconds, M=minutes, h=hours, d=days, w=weeks, m=months, y=years (default are d - days)\n";
  print "  -v|--verbose\tdisplay deleting files\n";
  print "  -r|--recursive\twalk directories recursive\n";
  print "  -d|--dry-run\tdo not actually perform the deletion\n";
  print "  -n|--newer\tdelete files that newer than specified age instead of old files (inverting)\n";
  print "\n";
}

sub del_tree
{
my $dir = shift;

}

#-------------------------------------Вернуть длину строки--------------------------------------
sub strlen
{
my $s = shift;
my $count = 0;
  
  while ($s =~ /./g) {
    $count++;
  }
  return $count;
}

#------------Добавить заданный символ в начале строки до получения заданной длины строки-----------
sub append_before_str($$$)
{
my $src_str = shift;
my $symb = shift;
my $target_length = shift;
my $result = $src_str;

  while (strlen($result) < $target_length) {
    $result = $symb . $result;
  }
  return $result;
}

#------------------------Дата/время в формате yyyy-mm-dd hh:mm:ss--------------------------
sub get_timestamp
{
my $custom_time = shift;
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);# = localtime();
my $result;

  if (!defined($custom_time)) {
    $custom_time = time();
  }
  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($custom_time);
  $result = 1900 + $year;
  $result .= "-" . append_before_str($mon, "0", 2);
  $result .= "-" . append_before_str($mday, "0", 2);
  $result .= " " . append_before_str($hour, "0", 2);
  $result .= ":" . append_before_str($min, "0", 2);
  $result .= ":" . append_before_str($sec, "0", 2);

  return $result;
}

#-------------------------Добавить в строку ещё одно сообщение об ошибке-----------------------------
sub store_error
{
my $existed_messages = shift;
my $new_message = shift;
my $result;

  $result = $existed_messages . $new_message . $ERROR_MESSAGES_DIVIDER;
  return $result;
}

#----------------------------- Установить значения параметров по умолчанию ----------------------------
sub set_default_params()
{
my @params = ();

  $params[$par__recursive] = 0;
  $params[$par__verbose] = 0;
  $params[$par__help] = 0;
  $params[$par__dry_run] = 0;
  $params[$par__newer] = 0;

  $params[$par__dir] = undef;
  $params[$par__mask] = undef;
  $params[$par__age] = undef;

  $params[$par__parse_errors] = "";
  return @params;
}

#---------------------------------------Разбор строки с возрастом файла-------------------------------
sub parse_age
{
my $raw_age = shift;
my $limit_time = -1;
my ($value, $measure, $measure_size);
my $current_time = time();

  if ($raw_age =~ /^(\d+)([smhdwMy]?)$/) {
    # указано число и, возможно, единица измерения
    $value = $1;
    $value *= 1;
    $measure = $2;
    $measure = "d" if ($measure eq "");

    $limit_time = $current_time - $value if ($measure eq "s" || $measure eq "S"); # seconds
    $limit_time = $current_time - 60 * $value if ($measure eq "M"); # minutes
    $limit_time = $current_time - 3600 * $value if ($measure eq "h" || $measure eq "H"); # hours
    $limit_time = $current_time - 3600*24 * $value if ($measure eq "d" || $measure eq "D"); # days
    $limit_time = $current_time - 3600*24*7 * $value if ($measure eq "w" || $measure eq "W"); # weeks
    $limit_time = $current_time - 3600*24*31 * $value if ($measure eq "m"); # months
    $limit_time = $current_time - 3600*24*365 * $value if ($measure eq "y" || $measure eq "Y"); # years
  }
  return $limit_time;
}

#------------------------Разбор переданных параметров командной строки----------------------------
sub parse_arguments
{
my @a = @_;
my $elem;
my @params = set_default_params;
my $sn = 0;
my @errors = ();

  foreach $elem(@a) {
    if ($elem eq "-h" || $elem =~ /^-+help$/i) {
      $params[$par__help] = 1;
      last;
    }
    if ($elem eq "-v" || $elem =~ /^-+verbose$/i) {
      $params[$par__verbose] = 1;
      next;
    }
    if ($elem eq "-r" || $elem =~ /^-+recursive$/i) {
      $params[$par__recursive] = 1;
      next;
    }
    if ($elem eq "-d" || $elem =~ /^-+dry-run$/i) {
      $params[$par__dry_run] = 1;
      next;
    }
    if ($elem eq "-n" || $elem =~ /^-+newer$/i) {
      $params[$par__newer] = 1;
      next;
    }
    #if ($elem =~ /^-/) {
    #  $params[$par__parse_errors] = store_error($params[$par__parse_errors], "unsupported named argument \"$elem\"");
    #  next;
    #}

    # обязательные последовательные параметры (каталог, маска, возраст)
    $sn++;
    #print "sn=$sn $elem\n";
    if ($sn == 1) {
      $params[$par__dir] = $elem;
      if (! -d $params[$par__dir]) {
        $params[$par__parse_errors] = store_error($params[$par__parse_errors], "directory \"$params[$par__dir]\" not exists");
      }
      next;
    }
    if ($sn == 2) {
      $params[$par__mask__raw] = $elem;
      $params[$par__mask] = files_mask_to_regular($elem);
      next;
    }
    if ($sn == 3) {
      $params[$par__age__raw] = $elem;
      $params[$par__age] = parse_age($elem);
      if ($params[$par__age] < 0) {
        $params[$par__parse_errors] = store_error($params[$par__parse_errors], "can not parse age");
      }
      next;
    }
    
    # слишком много параметров
    $params[$par__parse_errors] = store_error($params[$par__parse_errors], "too many parameters");
    #push(@errors, "too many parameters");
    last;
  }
  #if ($params[$par__dry_run]) {
  #  # режим эмуляции без реального удаления файлов включает подробный (verbose) режим
  #  $params[$par__verbose] = 1;
  #}
  return @params;
}

#---------------------------- Проверить, что указаны все обязательные параметры ------------------------------
sub check_required_parameters
{
my @params = @_;

  if (!defined($params[$par__dir])){
    $params[$par__parse_errors] = store_error($params[$par__parse_errors], "directory is not defined");
  }
  if (!defined($params[$par__mask])){
    $params[$par__parse_errors] = store_error($params[$par__parse_errors], "mask is not defined");
  }
  if (!defined($params[$par__age])){
    $params[$par__parse_errors] = store_error($params[$par__parse_errors], "age is not defined");
  }
  return @params;
}

#-----------Маску файлов используемую в ОС с применением символов * и ? заменить на регулярное выражение----------
sub files_mask_to_regular
{
my $mask = shift;

  # *.txt	-> 	(.*?)\.txt
  # *.tx*	->	(.*?)\.tx(.*?)
  $mask =~ s/\./\\\./g;			# замена точки в маске файла
  $mask =~ s/\?/\./g;			# замена ? в маске файла
  $mask =~ s/\*/\.\*\?/g;		# замена * в маске файла
  $mask = "^" . $mask . "\$";		# beginning and end of string
  return $mask;
}

#-------------------Удаление файлов согласно заданным параметром------------------
sub delete_files
{
my $dir = shift;
my $level = shift;
my @params = @_;
my $elem;
my @files_and_dirs;
my $path;
my $mtime;
my $file_timestamp;
my $space = "";
my $delete_flag;

  for (my $i=0; $i<$level; $i++) {
    $space .= "  ";
  }
  if ($params[$par__verbose]) {
    print $space . "enter to $dir\n";
  }

  #get content of directory
  opendir(DIR, $dir);
  @files_and_dirs = readdir(DIR);
  closedir(DIR);

  foreach $elem(@files_and_dirs) {
    #exclude . and ..
    next if ($elem eq ".");
    next if ($elem eq "..");
    $path = $dir . $SLASH . $elem;
    if ( -d $path && $params[$par__recursive]) {
      # текущий элемент каталог и нужно пройти внутрь всех каталогов
      delete_files($path, $level+1, @params);
      next;
    }
    # текущий объект - файл
    next if ($elem !~ /$params[$par__mask]/);
    $mtime = (stat($path))[9];
    $delete_flag = 0;
    if ($params[$par__newer] == 0) {
      # удалять старые файлы
      if ($mtime < $params[$par__age]) {
        $delete_flag = 1;
     }
    }
    else {
      # удалять новые файлы
      if ($mtime > $params[$par__age]) {
        $delete_flag = 1;
     }
    }
    if ($delete_flag) {
      # файл подлежит удалению
      if ($params[$par__verbose] || $params[$par__dry_run]) {
        $file_timestamp = get_timestamp($mtime);
        print $space . "delete \"$path\" [$file_timestamp]\n";
      }
      if (!$params[$par__dry_run]) {
        # выключен режим эмуляции - реальное удаление
        unlink($path);
      }
    }
  }
}

#--------------------Вывести список параметров и сообщения об ошибках, если такие есть---------------------
sub print_params
{
my @params = @_;
my $age_criteria;

  if ($params[$par__newer]) {
    $age_criteria = "newer";
  }
  else {
    $age_criteria = "older";
  }

  print "--- params: ---\n";
  print "verbose: $params[$par__verbose]\n";
  print "recursive: $params[$par__recursive]\n";
  print "help: $params[$par__help]\n";
  print "dir: $params[$par__dir]\n";
  print "mask: $params[$par__mask__raw]\n";
  print "age: $params[$par__age__raw] ( $age_criteria " . get_timestamp($params[$par__age]) . ")\n";
  print "dry-run: $params[$par__dry_run]\n";
  print "newer: $params[$par__newer]\n";
  #print "parse_errors: params[$par__parse_errors]";

  if ($params[$par__parse_errors] ne "") {
    my @parse_errors = split(/\|/, $params[$par__parse_errors]);
    print "Found errors:\n";
    foreach my $elem(@parse_errors) {
      print "  - $elem\n";
    }
    #print "E: @parse_errors\n";
  }
  print "---\n\n";
}


#-----------------------------------main----------------------------------
if (-f "/etc/passwd") {
  $SLASH = "/";
}
else {
  $SLASH = "\\";
}
my @params = parse_arguments(@ARGV);
if ($params[$par__help]) {
  # явно запрошена справка
  help();
  exit(0);
}
@params = check_required_parameters(@params);
if ($params[$par__parse_errors] ne "") {
  # есть ошибки в параметрах
  print_params(@params);
  help();
  die;
}

print_params(@params) if ($params[$par__verbose]);
delete_files($params[$par__dir], 0, @params);
