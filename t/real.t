use strict;
use lib 't/lib';  # distributed here until changes are incorporated into the real version
use Apache::test qw(test);

my %requests = 
  (
   2  => '/docs/simple.html',
   3  => {uri=>'/docs/simple.html',
          headers=>{'Accept-Encoding' => 'gzip'},
         },
  );


my %special_tests = 
  (
   3 => {content => \&decomp}, 
  );

use vars qw($TEST_NUM);
print "1.." . (1 + keys %requests) . "\n";
test ++$TEST_NUM, 1; # Loaded successfully

foreach my $testnum (sort {$a<=>$b} keys %requests) {
  &test_outcome(Apache::test->fetch($requests{$testnum}), $testnum);
}

######################################################################
use Compress::Zlib;

sub decomp {
  my $content = shift;
  my $file = 't/tmp';
  open TMP, ">$file" or die "Can't create $file: $!";
  print TMP $content;
  close TMP;
  
  my $gz = gzopen($file, 'rb') or die $!;
  my $buffer;
  $gz->gzread($buffer, 400);
  
  unlink $file;
  return $buffer;
}

sub test_outcome {
  my ($response, $i) = @_;
  my $content = $response->content;
  
  my $expected;
  if ($special_tests{$i}{content}) {
    $content = $special_tests{$i}{content}->($content);
  }
  my $ok = $content eq ($expected = `cat t/check/$i`);
  Apache::test->test(++$TEST_NUM, $ok);
  my $headers = $response->headers_as_string();
  print "$i Result:\n$content\n$i Expected: $expected\n" if ($ENV{TEST_VERBOSE} and not $ok);
}
