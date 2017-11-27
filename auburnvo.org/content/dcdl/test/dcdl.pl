#!/usr/bin/perl -w
#
# The Dreamcast Downloader v0.9
# Copyright (C) Scott Robinson 2000-2002
#
# This script requires VirtuaMUnstaz' (http://virtuamunstaz.de) vmi/vms file
# info reader/creator. (vmu) Apply the patchs included.
#
# This script also requires RAMTronics' (http://rvmu.maushammer.com/) VMUX
# convertor software.
#
# This script also requires "wpng" tool from the pngbook package available
# at ftp://libpng.org/pub/png/.
#
# This script also requires libcgi/CGI.pm available at CPAN.
#
# The DCDL Package includes the emb2bmp.pl, Copyright (c) 2000 Take.
#
# So go get them.
#

use CGI;
use File::Basename;

$dcdl_version = "v0.9";

# Administrator Variables

#
# VOA Original Configuration
#

#$dcdl_root = '/home/scott/dcdl/';
#$tool_root = $dcdl_root . 'bin/';
#$vms_root = './data/';
#$work_path = 'http://www.reactor-core.org/~scott/dcdl-work/';
#$work_root = '/home/scott/public_html/dcdl-work/';
#$vmutool = $tool_root . 'vmu';
#$dcitool = $tool_root . 'vmx2dci';
#$pngtool = $tool_root . 'wpng';
#$form_filename_ex = 'VOORATAN.R00';
#$copyright = 'SSR <scott@tranzoa.com>';

#
# VOA tranzoa.net mirror configuration
#

#$dcdl_root = '/home/scott/public_html/VOA/vo-archive/.internal/dcdl/';
#$tool_root = $dcdl_root . 'bin/';
#$vms_root = './data/';
#$work_path = 'http://www.tranzoa.net/~scott/VOA/vo-archive/.internal/dcdl-work/';
#$work_root = '/home/scott/public_html/VOA/vo-archive/.internal/dcdl-work/';
#$vmutool = $tool_root . 'vmu';
#$dcitool = $tool_root . 'vmx2dci';
#$pngtool = $tool_root . 'wpng';
#$form_filename_ex = 'VOORATAN.R00';
#$copyright = 'SSR <scott@tranzoa.com>';

#
# Auburn VO Crew configuration
#

$dcdl_root = '/accounts/scottr/www/www.auburnvo.org/html/content/dcdl/.internal/';
$tool_root = $dcdl_root . 'bin/';
$vms_root = './data/';
$work_path = 'http://www.auburnvo.org/content/dcdl/.internal/work/';
$work_root = '/accounts/scottr/www/www.auburnvo.org/html/content/dcdl/.internal/work/';
$vmutool = $tool_root . 'vmu';
$dcitool = $tool_root . 'vmx2dci';
$pngtool = $tool_root . 'wpng';
$form_filename_ex = 'VOORATAN.R00';
$copyright = 'SSR <scott@tranzoa.com>';

# !!! VOA Extension
$embtool = $dcdl_root . "emb2bmp.pl $dcdl_root";
$bmptool = $tool_root . 'bmp2png';
# !!! End VOA Extension

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# % Beginning of function code %
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# -- look at the bottom of the script to find the code that calls the
# -- various subroutines.

# Write a prettified list of the $vms_root. Our purpose in life.

sub list
{
    print $cgi->header(), $cgi->start_html('[DCDL] File Index');

    print "<P>Welcome to a Dreamcast Downloader file index at the <A ",
          "HREF=\"http://www.reactor-core.org/vo/\">Virtual-On ",
          "Archive</A>.</P>";

    # Optional Header File...

    if (open FILE, "./index.html")
    {
        while(<FILE>) { print $_; }
        close FILE;
    }

    # Setup and display the chunky form section.

    %format_types = ( 'vms' => '.VMI/.VMS combination (DC)',
                      'dci' => '.DCI (PC)'
                    );

    print $cgi->start_form(), $cgi->p,
            "Enter the filename to be used <b>on-VMU</b>: ",
            $cgi->textfield('name', $form_filename_ex),
            " (<i>replace the \'</i><mono>00</mono><i>\' with the digits of your choice</i>)",
            $cgi->br,
            "<P>Select a VMU file format: ",
            $cgi->popup_menu('format',
                             ['vms', 'dci'],
                             'vms',
                             \%format_types),
            "</P>";

    @vmsdir = glob("$vms_root/*.VMS");
    print "<P>Select a VMU file to download:</P>";

    # Indexing Loop

    $vms_file_count = 0;

    foreach $vms_file (@vmsdir)
    {
        $vms_file_base = basename($vms_file);
        $vms_file_base_noxt = basename($vms_file, "\.VMS");

        $vms_header_name = "[<B>" . $vms_file_base_noxt . "</B>]\n";

        $vms_info_size = int((-s $vms_file)/512) . "B\n";

        # VMS Information File

        $vms_header = $vms_info_body = "";
        $vms_info_file = $vms_file . "\.txt";

        if (open FILE, $vms_info_file)
        {
            $vms_header = <FILE>;

            while (<FILE>)
            {
                $vms_info_body .= $_;
            }

            close FILE;
        }

        if (!$vms_header) { $vms_header = "No information available."; }
        if (!$vms_info_body) { $vms_info_body = "No information available."; }

        # VMS XT Perl Information File

        $vms_info_image = $vms_header_autod = $vms_xt_file = "";

        if (-r $vms_file . "\.xt")
        {
            $vms_xt_file = $vms_file . "\.xt";
        }
        elsif (-r $vms_root . "/dir.xt")
        {
            $vms_xt_file = $vms_root . "/dir\.xt";
        }
        else
        {
            $vms_info_image = "";   # I would so rather have a little "X" image. Want to supply?
            $vms_header_autod = "None Available";
        }

        if (open FILE, $vms_xt_file)
        {
            $vms_xt_in_temp = "";

            while (<FILE>) { $vms_xt_in_temp .= $_ };

            close FILE;

            eval $vms_xt_in_temp;
        }

        # Update VMS count variable

        $vms_file_count = $vms_file_count + 1;

        # Put all the pieces of information together!

        print "<table border=\"1\" cellspacing=\"0\" bgcolor=\"white\">";
        print "<tr>";
                print "<th>";
                    print $vms_info_image;
                    print $vms_info_size;
                print "</th>";
                print "<td>", $vms_header_name, "</td>";
                print "<td width=\"100%\">", $vms_header, "</td>";
                print "<td>Auto Download:</td>";
        print "</tr>";
        print "<tr>";
                print "<td><center>";
                    print "<INPUT TYPE=\"radio\" NAME=\"file\" VALUE=\"", $vms_file_base, "\">\n";
                print "</td></center>";
                print "<td colspan=\"2\">", $vms_info_body, "</td>";
                print "<td>", $vms_header_autod, "</td>";
        print "</tr>";
        print "</table><br>";
    }

    print $cgi->hidden('mode', 'get');

    print $cgi->submit('Download Selected File Now!'), "&nbsp;", $cgi->reset, $cgi->end_form;

    print "<div align=right><small>DCDL" . $dcdl_version . " - Copyright 2000, 2001 (C) $copyright</small></div>", $cgi->end_html;
}

# Writes a redirect request to a specially setup version of the requested .VMS file.

sub get
{
    $request_vmu_name = $cgi->param('name');
    $request_vmu_format = $cgi->param('format');
    $request_vms = $cgi->param('file');

    # Paranoia checking ...

    if (!$request_vmu_name || !$request_vmu_format || !$request_vms) { return &list; };

    # ... and setting up of the filename time hash.

    open HASH, "date +%d%H%M%S |";
    $vmu_hash = <HASH>;
    chomp($vmu_hash);
    $vms_file = $vms_root . $request_vms;
    $vmu_name = substr($request_vmu_name, 0, 12);

    # Make sure everything exists or doesn't exist!

    if (! -r $vms_file)
    {
        print $cgi->header('text/html', '404 Not Found');

        print $cgi->start_html('[DCDL] VMU file not found'), "<P>The ",
                                "requested VMU file (",
                                $vms_file, ") is not present in this ",
                                "database.",
              $cgi->end_html;
        exit;
    }
    elsif (-e $work_root . $vmu_hash)
    {
        print $cgi->header(-type=>'text/html',
                           -status=>'503 Service Unavailable');

        print $cgi->start_html('[DCDL] Overloaded'), "<P>The system is ",
                               "currently overloaded. Please wait a few ",
                               "minutes before trying your request again. ",
              $cgi->end_html; exit;
        exit;
    }

    # !!! I should probably abstract out the '/tmp' reference.

    @cpargs = ('cp', $vms_file, "/tmp/$vmu_hash");
    system(@cpargs);

    # Harness the power of other people's tools, and convert the files!

    $vmu_hash_dci = $vmu_hash . "\.DCI";
    $vmu_hash_vmi = $vmu_hash . "\.VMI";
    $vmu_hash_vms = $vmu_hash . "\.VMS";

    open STDERR, "$vmutool -r $vmu_hash -f \"$vmu_name\" -c \"$copyright\" /tmp/$vmu_hash |";
    close STDERR;
    open STDERR, "$dcitool /tmp/$vmu_hash_vmi /tmp/$vmu_hash_dci |";
    close STDERR;
    
    @mvargs = ('mv', "/tmp/$vmu_hash_vmi", "/tmp/$vmu_hash_vms", "/tmp/$vmu_hash_dci", "$work_root");
    system(@mvargs);

    # Kick back a redirect to the proper file format. :-)

    if ($cgi->param('format') eq 'dci') { print $cgi->redirect($work_path.$vmu_hash_dci); }
    elsif ($cgi->param('format') eq 'vms') { print $cgi->redirect($work_path.$vmu_hash_vmi); }
}

# Writes an image/png of the VMU file icon.

sub imager
{
    $request_vms = $cgi->param('file');
    if (!$request_vms) { return &list; };

    $vms_file = $vms_root . $request_vms;

    if (! -r $vms_file)
    {
        print $cgi->header('text/html', '404 Not Found');

        print $cgi->start_html('[DCDL] VMU file not found'), "<P>The ",
                                "requested VMU file (",
                                $vms_file, ") is not present in this ",
                                "database.",
              $cgi->end_html;
        exit;
    }

    print $cgi->header('image/png');

    open PNGDATA, "$vmutool -i -p \"$pngtool\" $vms_file |";
    while (<PNGDATA>) { print $_; }
    close PNGDATA;
}

# !!! VOA Extension
# Writes an image/png of the Emblem data inside a .VMS.

sub emblemizer
{
    $request_vms = $cgi->param('file');
    if (!$request_vms) { return &list };

    $vms_file = $vms_root . $request_vms;

    if (! -r $vms_file)
    {
        print $cgi->header('text/html', '404 Not Found');

        print $cgi->start_html('[DCDL] VMU file not found'), "<P>The ",
                                "requested VMU file (",
                                $vms_file, ") is not present in this ",
                                "database.",
              $cgi->end_html;
        exit;
    }

    print $cgi->header('image/png');

    open BMPDATA, "$embtool $vms_file | $bmptool |";
    while (<BMPDATA>) { print $_; }
    close BMPDATA;
}

# !!! End VOA Extension

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# % Beginning of program code %
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

$cgi = new CGI;

$pmode = $cgi->param('mode') || "list";

if ($pmode eq 'list') { &list; }
elsif ($pmode eq 'get') { &get; }
elsif ($pmode eq 'imager') { &imager; }

# !!! VOA Extension
elsif ($pmode eq 'emblemizer') { &emblemizer; }
# !!! End VOA Extension

else { &list };

# Not implemented
#elsif ($pmode eq 'post') { &post; }

exit;
