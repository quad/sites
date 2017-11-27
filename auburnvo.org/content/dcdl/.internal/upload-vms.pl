#!/usr/bin/perl
#!/usr/bin/perl -w
# Multipart form uploader.

use CGI;
use MIME::Base64;

# -----------------------------------------------------
# encryption table
@base64    = ('A','B','C','D','E','F','G','H','I','J',
              'K','L','M','N','O','P','Q','R','S','T',
              'U','V','W','X','Y','Z','a','b','c','d',
              'e','f','g','h','i','j','k','l','m','n',
              'o','p','q','r','s','t','u','v','w','x',
              'y','z','0','1','2','3','4','5','6','7',
              '8','9','+','/','=');

@dp_base64 = ('A','Z','O','L','Y','N','d','n','E','T',
              'm','P','6','c','i','3','S','z','e','9',
              'I','y','X','B','h','D','g','f','Q','q',
              '7','l','5','b','a','t','M','4','r','p',
              'K','J','j','8','C','u','s','x','R','F',
              '+','k','2','V','0','w','U','G','o','1',
              'v','W','H','/','=');

######################################################################
#######
# decode_dp_base64(<DP base 64'd data stream>)
# returns an array derived from DP base64 decoding the data stream.
#
# Argument: Character lines encoded by DP_BASE64.
# Back: Encoded bit character lines.
######################################################################
######
sub decode_dp_base64 {
    my $src = shift;
    my $bindata = ();
    my $i;

    my $count = 0;
    foreach my $c(split(//,$src))
    {
        if ($c eq '-') {
            last;
        }

        for ($i = 0; $i < 65; $i++)
        {
            if ($c eq $dp_base64[$i]) {
                $count++;
                $bindata .= $base64[$i];
                if ($count == 77) {
                    $count = 0;
                    $bindata .= "\n";
                }
                last;
            }
        }
    }

    return $bindata;
}

sub index_end
{
    print $cgi->start_multipart_form(), $cgi->p,
            "Select VMU file to be uploaded: ",
            "<input type=VMFILE accept=\"*\" name=\"vmufile\">",
            $cgi->hidden('mode', 'upload'),
            $cgi->br,
            "Enter description of file: <br>",
            "<textarea align=center cols=60 rows=10 name=\"desc\">",
            "The first line is your file's description header.\n",
            "Everything after goes in your file's description body.",
            "</textarea>",
            $cgi->br,
            $cgi->submit('Upload Selected File Now!'), "&nbsp;",
            $cgi->reset, "</P>", $cgi->end_form;

    print "<div align=right>DCDL Upload Test - Copyright 2000 (C) SSR</div>", $cgi->end_html;
}

sub index
{
    print $cgi->header(), $cgi->start_html('[DCDL] Uploader!');

    print "<P>Welcome to the DCDL uploader. Give a file, get a bit ",
          "o' recognition. There was more witty stuff said, but I'm ",
          "burnt.</P>";

    &index_end;
}

sub upload
{
    $filename = $cgi->param('vmufile');
    $desc = $cgi->param('desc');

    if (!$filename)
    {
        print $cgi->header(-status=>"400 Bad request (dumbass)");
        exit 0;
    }

    # See if we can't determine the header data and split up to the stuff we
    #  want?

    ($post_filename, $post_fs, $post_bl, $post_tp, $post_fl, $post_of,
     $post_tm_rest) = split /\&/, $filename;

    $post_data = $post_tm_rest;
    $post_data =~ s/tm=\d*\s*//;

    if (!$post_filename || !$post_data)
    {
        print $cgi->header(-status=>"400 Bad request (no ticket)");
        exit 0;
    }

    # Convert base64'ed VMS data into real binary
    $base64_data = decode_dp_base64($post_data);
    $raw_data = decode_base64($base64_data);

    $_ = $post_filename;
    if (/filename=(.*)/) { $vms_filename = $1 };

    open HASH, "date +%s |";
    $vmu_hash = <HASH>;
    chomp($vmu_hash);
    $out_filename = $vmu_hash . "-" . $vms_filename . "-upload.VMS";

    $path = "./data/";

    unless (open (OUTFILE, "> $path/$out_filename"))
    {
        print $cgi->header(), $cgi->start_html('[DCDL] Error!');
        print $cgi->p, "Weren't able to write VMS file. </p>";
        print $cgi->end_html;
        exit 0;
    }
    else
    {
        print OUTFILE $raw_data;
        close OUTFILE;
    }

    $out_filename_desc = $out_filename . ".txt";
    unless (open (OUTFILE, "> $path/$out_filename_desc"))
    {
        print $cgi->header(), $cgi->start_html('[DCDL] Error!');
        print $cgi->p, "Weren't able to write desscription file. </p>";
        print $cgi->end_html;
        exit 0;
    }
    else
    {
        print OUTFILE $desc;
        close OUTFILE;
    }

    print $cgi->header(), $cgi->start_html('[DCDL] Thanks!');
    print $cgi->p, "We received <mono>", $vms_filename, "</mono> and dumped ",
           "to <mono>", $out_filename, "</mono>. Thanks!</p>\n";

    &index_end;
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# % Beginning of program code %
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Multipart hack to handle DreamPassport's gimpified MIME handling.

# Many evil thanks go to bod @ openprojects! I was going to just hack the
# CONTENT_TYPE itself. ;-) This version exploits code inside CGI.pm as well!

for ($ENV{HTTP_USER_AGENT})
{ $_ = "MSIE 3.01; Mac (really DP)" if /DreamPassport/ }

# Shall we commence?

$cgi = new CGI;

$pmode = $cgi->param('mode') || "index";

if ($pmode eq 'index') { &index; }
elsif ($pmode eq 'upload') { &upload; }
else { &index };

exit;
