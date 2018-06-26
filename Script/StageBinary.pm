# ==============================================================================
# Copyright (C) 2010 - DIGITEO - Pierre MARECHAL <pierre.marechal@scilab.org>
# ==============================================================================

package CC::StageBinary;


# System dependencies
use strict;
use Exporter;
use Cwd;
use File::Copy;
use File::Basename;
use File::stat;
use File::Path;
use Digest::file qw(digest_file_hex);

# Internal dependencies
use CC::Message;
use CC::State;
use CC::Transfer;
use CC::SysUtils;
use CC::DateUtils;
use CC::Mail;

our @ISA    = ('Exporter');
our @EXPORT = qw(&stageBinary);

BEGIN
{

}

END
{

}


# ==============================================================================
# Main Function
# ==============================================================================

sub stageBinary
{
    if( ($::configModules{'binary'} ne 'yes') || $::continue)
    {
        return 0;
    }

    $::logini_obj->start('ProductionDuBinaire');

    # Liste des fichiers concernés par cette opération
    # ==========================================================================

    $::files{'log:binary:binary.html'}         = $::configPaths{'log'}.$::sep.'binary.html';
    $::files{'log:binary:binary.txt'}          = $::configPaths{'log'}.$::sep.'binary.txt';
    $::files{'log:binary:targzbin.txt'}        = $::configPaths{'log'}.$::sep.'targzbin.txt';
    $::files{'log:binary:iss.txt'}             = $::configPaths{'log'}.$::sep.'iss.txt';
    $::files{'log:binary:iss_mkl.txt'}         = $::configPaths{'log'}.$::sep.'iss_mkl.txt';
    $::files{'log:binary:iss_fftw.txt'}        = $::configPaths{'log'}.$::sep.'iss_fftw.txt';
    $::files{'log:binary:create_iss.txt'}      = $::configPaths{'log'}.$::sep.'create_iss.txt';
    $::files{'log:binary:create_iss_mkl.txt'}  = $::configPaths{'log'}.$::sep.'create_iss_mkl.txt';
    $::files{'log:binary:create_iss_fftw.txt'} = $::configPaths{'log'}.$::sep.'create_iss_fftw.txt';
    $::files{'log:binary:add_modules.txt'}     = $::configPaths{'log'}.$::sep.'add_modules.txt';
    # Suppression du contenu des logs
    # (ou création des fichiers s'il n'existaient pas)
    # ==========================================================================

    reset_files(
    $::files{'log:binary:binary.html'},
    $::files{'log:binary:binary.txt'},
    $::files{'log:binary:targzbin.txt'},
    $::files{'log:binary:iss.txt'},
    $::files{'log:binary:iss_mkl.txt'},
    $::files{'log:binary:iss_fftw.txt'},
    $::files{'log:binary:create_iss.txt'},
    $::files{'log:binary:create_iss_mkl.txt'},
    $::files{'log:binary:create_iss_fftw.txt'},
    $::files{'log:binary:add_modules.txt'}
    );

    # Action !
    # ==========================================================================
    my $module_error_code = binary();



    # Transfert des fichiers
    # ==========================================================================

    if( $::configFtp{'enable'} eq 'yes')
    {
        send_scp_txt_files
        (
        $::configPaths{'FTP'},
        $::files{'log:binary:binary.html'},
        $::files{'log:binary:binary.txt'},
        $::files{'log:binary:targzbin.txt'},
        $::files{'log:binary:iss.txt'},
        $::files{'log:binary:iss_mkl.txt'},
        $::files{'log:binary:iss_fftw.txt'},
        $::files{'log:binary:create_iss.txt'},
        $::files{'log:binary:create_iss_mkl.txt'},
        $::files{'log:binary:create_iss_fftw.txt'}
        );
        # Binaire Scilab
        # ======================================================================

        if( ($::configMain{'compiler'} ne "Visual C++ 2005 express")
        && ($::configMain{'bin_from_server'} ne 'yes') )
        {
            send_scp_files($::files{'binary:archive_scilab'},
            $::files{'binary:md5_archive_scilab'});
        }
        # Binaire MKL
        # ======================================================================

        if( $::configOS{'is_windows'}
        && ($::configFftwmkl{'mkl_support'} eq 'yes') )
        {
            send_scp_files($::files{'binary:MKL'},
            $::files{'binary:md5_MKL'});
        }

        # Binaire FFTW
        # ======================================================================

        if( $::configOS{'is_windows'}
        && ($::configFftwmkl{'fftw_support'} eq 'yes') )
        {
            send_scp_files($::files{'binary:FFTW'},
            $::files{'binary:md5_FFTW'});
        }

    }

    # Error management
    # ==========================================================================

    if($module_error_code != 0)
    {
        my $mail_to         = $::configMail{'mail_failed'};
	    my $mail_subject    = $::configOS{'name'}.$::configOS{'arch'}."-";
	    if($::configGit{'tag'} ne '')
	    {
	        $mail_subject  .= $::configGit{'tag'};
	    }
	    else
	    {
	        $mail_subject  .= 'master';
	    }
	    $mail_subject      .= '  Failed in Binary Stage';

        my $mail_message;
        $mail_message    = 'OS       = '.$::configMain{'type'}         ."\r\n";
        $mail_message   .= 'Version  = '.$::scilab{'version'}       ."\r\n";
        $mail_message   .= 'Host     = '.$::configMain{'host'}          ."\r\n";
        $mail_message   .= 'Arch     = '.$::configOS{'arch'}       ."\r\n";
        $mail_message   .= 'Compilo  = '.$::configMain{'compiler'}   ."\r\n\r\n";

	    $mail_message   .= 'http://compilationchain.scilab.org/index.php?os=';
        if($::configOS{'is_macosx'})
        {
           	$mail_message    .= 'macosx';
        }
        elsif($::configOS{'is_windows'})
        {
           	$mail_message    .= 'windows';
        }
        else{
           	$mail_message    .= 'linux';
        }
    	if( $::configOS{'is_macosx'} && ( $::configGit{'tag'} eq '' || $::configGit{'tag'} eq 'master')){
    		$mail_message    .= '&mode=release';
    	}
    	elsif($::configGit{'tag'} eq '' && $::configOS{'arch'} eq '32bits'){
    		$mail_message    .=	'&mode=release';
    	}
    	elsif($::configGit{'tag'} eq '' && $::configOS{'arch'} eq '64bits'){
    		$mail_message    .=	'&mode=64-bits';
    	}
    	elsif($::configOS{'arch'} eq '32bits'){
    		$mail_message    .= '&mode='.$::configGit{'tag'};
    	}
    	else{
    		$mail_message    .= '&mode='.$::configGit{'tag'}."_64-bits";
    	}
    	$mail_message    .= '&module=4&download=0&date='.$::date->get_shortdate();

    	my $filetoshrink = '';
    	if($module_error_code == '03031'){
			$filetoshrink =         $::files{'log:binary:iss.txt'};
			$mail_message	 .= "&detail=iss.txt\r\n";
    	}
    	else{
    		$filetoshrink = "binary.html";
    	}
		$mail_message 	.= "\r\n\n Dernières lignes du fichier : \n";
		open(FILE, $filetoshrink);
		my @ligne = <FILE>;
		my @ligne100 = (reverse @ligne)[0..50];
		for(my $i = scalar @ligne100; $i>0; $i--){
			$mail_message .= $ligne100[$i];
		}
		close(FILE);
        sendMail($mail_to,
        $mail_subject,
        $mail_message);
        print "\r\n Code d'erreur de binary() : $module_error_code \r\n\n";
        $::continue = 1;
        return $module_error_code;
    }
    # Log end
    # ==========================================================================

    $::logini_obj->stop('ProductionDuBinaire',$module_error_code);
    return $module_error_code;
}


# ==============================================================================
# Author : Pierre MARECHAL
# Date   : 25 oct 2004
#
# But    : Production du binaire
#
## @fn int binary(void)
# @author Pierre MARECHAL
# @date 25 oct 2004
#
# @par Description:
#    Production du binaire ( Linux/Unix + Windows ) ou récupération du binaire
#    suivant la valeur de la variable $::configMain{'bin_from_server'}
#
# @return
#    @li 0 if all is ok
#    @li A code between 400 and 499 if there is an error
#
# ==============================================================================

sub binary
{
    my $returnCode=0;
    my $md5;

    # Pour le nettoyage du help

    my @languages = ("en_US","fr_FR");
    my $language;

    my @listOfElements;
    my $element;

    my @manDirs;
    my $manDir;



    reset_files
    (

    );

    # Récupération de l'environnement initial
    import_state();

    if($::configMain{'bin_from_server'} eq 'no')
    {
        # On produit vraiment le binaire ( i.e on ne le récupère pas depuis
        # le serveur)

        # ======================================================================
        # Nettoyage
        # ======================================================================



        #
        # Construction de l'architecture nécéssaire sous MacOSX
        #

        if( $::configOS{'is_macosx'} )
        {
            #
            # Construction de l'architecture nécéssaire sous MacOSX
            #

            my $dir2create;

            create_message('03300');

            $dir2create = $::configPaths{'binary'}.'/'.$::scilab{'version'}.'.app';
            unless( mkdir($dir2create) )
            {
				unless(deleteDir($::configPaths{'binary'}.'/'.$::scilab{'version'}.'.app')){
                    create_message('03301',$dir2create);
                    return '03301';
				}
            }

            $dir2create = $::configPaths{'binary'}.'/'.$::scilab{'version'}.'.app/Contents';

            unless( mkdir($dir2create) )
            {
                create_message('03301',$dir2create);
                return '03301';
            }

            $dir2create = $::configPaths{'binary'}.'/'.$::scilab{'version'}.'.app/Contents/MacOS';

            unless( mkdir($dir2create) )
            {
                create_message('03301',$dir2create);
                return '03301';
            }

            $dir2create = $::configPaths{'binary'}.'/'.$::scilab{'version'}.'.app/Contents/Resources';

            unless( mkdir($dir2create) )
            {
                create_message('03301',$dir2create);
                return '03301';
            }

            unless( chdir($::configPaths{'binary'}) )
            {
                create_message('03310',$::configPaths{'binary'});
                return '03310';
            }

            log_and_system('ln -s /Applications Applications');

            unless(-e $::configPaths{'binary'}.'/Applications')
            {
                create_message('03311',$::configPaths{'binary'});
                return '03311';
            }

            create_message('03302');

            #
            # Copie du fichier Info.plist dans $::configPaths{'binary'}/$::scilab{'version'}.app/Contents
            #

            create_message('03303');

            unless( copy($::configPaths{'compilation'}.'/'.$::scilab{'version'}.'/etc/Info.plist',$::configPaths{'binary'}.'/'.$::scilab{'version'}.'.app/Contents/Info.plist' ) )
            {
                create_message('03304');
                return '03304';
            }

            create_message('03305');

            #
            # Copie du fichier puffin.icns dans $::configPaths{'binary'}/$::scilab{'version'}.app/Contents/Resources
            #

            create_message('03306');

        	unless( copy($::configPaths{'compilation'}.'/'.$::scilab{'version'}.'/desktop/images/icons/puffin.icns',$::configPaths{'binary'}.'/'.$::scilab{'version'}.'.app/Contents/Resources/puffin.icns' ) )
        	{
                create_message('03307');
                return '03307';
        	}

            create_message('03308');

            #
            # Copie des fichiers :
            #  - ACKNOWLEDGEMENTS
            #  - CHANGES.md
            #  - COPYING
            #

            create_message('03320');

            my %files_to_copy;
            # TODO: is this really used ? it is probably a duplicate of later code to copy files, below
            $files_to_copy{'ACKNOWLEDGEMENTS'}    = 1;
            $files_to_copy{'CHANGES.md'}          = 1;
            $files_to_copy{'COPYING'}             = 1;

            foreach my $file (sort keys %files_to_copy)
            {
                unless( copy( $::configPaths{'compilation'}.'/'.$::scilab{'version'}.'/'.$file,$::configPaths{'binary'}) )
                {
                    create_message('03321');
                    return '03321';
                }
            }

            create_message('03322');
        }

        if( $::configOS{'is_unix'} )
        {
            if( $::configOS{'is_macosx'} )
            {
                $::configPaths{'binary:install'}  = $::configPaths{'binary'}.'/'.$::scilab{'version'}.'.app/Contents/MacOS';
            }
            else
            {
                $::configPaths{'binary:install'} = $::configPaths{'binary'}.'/'.$::scilab{'version'};
            }

            $::configPaths{'binary:thirdparty'} = $::configPaths{'binary:install'}.'/thirdparty';
            $::configPaths{'binary:modules'} = $::configPaths{'binary:install'}.'/share/scilab/modules/tclsci/tcl/';
            #
            # Lancement du "make install"
            #

            create_message('03200');

            unless( chdir($::configPaths{'compilation'}.'/'.$::scilab{'version'}))
            {
                create_message('03008',$::configPaths{'compilation'}.'/'.$::scilab{'version'});
                return '03008';
            }

            my $MakeInstallCmd;

            if($::configMain{'cli'})
            {
                $MakeInstallCmd = "make install > $::files{'log:binary:binary.txt'} 2>&1";
            }
            else
            {
                $MakeInstallCmd = "make install install-html > $::files{'log:binary:binary.txt'} 2>&1";
            }

            my $startMakeInstallTime  = time();
            $returnCode               = log_and_system($MakeInstallCmd);
            my $endMakeInstallTime    = time();
            my $duringMakeInstallTime = $endMakeInstallTime - $startMakeInstallTime;

            if($returnCode!=0)
            {
                create_message('03202');
                return '03202';
            }

            create_message('03203');

            #
            # Copie des librairies
            #

            my $library_list_file;
            my $library_directory = $::configPaths{'binary:install'}.$::sep.'lib'.$::sep.'thirdparty';
            my $library_directory_10_5 = $::configPaths{'binary:install'}.'/lib/thirdparty/';

            if( $::configOS{'is_linux'} )
            {
                $library_list_file = $::directory.'/etc/libraries.ini';
            }
            elsif( $::configOS{'is_macosx'} )
            {
                $library_list_file = $::directory.'/etc/libraries.macosx.ini';
            }

            create_message('03220');
            create_message('03230',$library_directory);
            unless( copyDir($::configPaths{'compilation'}.$::sep.$::scilab{'version'}.$::sep.'lib'.$::sep.'thirdparty',$library_directory) )
            {
                create_message('03221',$library_directory);
                return '03221';
            }

            # bin/ directory is empty (or does not exist) under Linux/Mac OS X
            #unless( copyDir($::configSvn{'base'}.$::sep.'SE'.$::sep.'Prerequirements'.$::sep.$::configSvn{'OS'}.$::sep.'bin',$library_directory,'subdir') )
            #{
            #    create_message('03221',$::configSvn{'base'}.$::sep.'SE'.$::sep.'Prerequirements'.$::sep.$::configSvn{'OS'}.$::sep.'bin');
            #    return '03221';
            #}

            unless( chdir($library_directory) )
            {
                create_message('03222',$library_directory);
                return '03222';
            }
			create_message('03225');
            #
            # Suppression des rpaths et information de debug
            #

            if($::configOS{'is_linux'})
            {
                create_message('03400');

                unless(chdir($::configPaths{'binary:install'}.'/lib'))
                {
                    create_message('03401');
                    return '03401';
                }

                my @so_files = <*/*so*>;

                foreach my $so_file (@so_files)
                {
                    if( (-f $so_file) && (! -l $so_file) && (! ($so_file =~ m /la$/ )) )
                    {
                        log_and_system('chrpath -k -d '.$so_file);

                        log_and_system('objcopy --only-keep-debug '.$so_file.' '.$so_file.'.debug');
                        log_and_system('objcopy --strip-debug '.$so_file);
                        log_and_system('objcopy --add-gnu-debuglink='.$so_file.'.debug'.' '.$so_file);
                    }
                }

                unless(chdir($::configPaths{'binary:install'}.'/bin'))
                {
                    create_message('03401');
                    return '03401';
                }

                log_and_system('chrpath -k -d scilab-bin');
                log_and_system('objcopy --strip-debug scilab-bin');
                log_and_system('chrpath -k -d scilab-cli-bin');
                log_and_system('objcopy --strip-debug scilab-cli-bin');

                create_message('03402');
            }
            elsif( $::configOS{'is_macosx'} )
            {
                # Global structures
                # --------------------------------------------------------------

                %::libraries        = ();
                %::librariesToTreat = ();

                # ==============================================================
                # build_library_path
                # + %libraries        : Existing libraries
                #                       (symbolic links included)
                # + %librariesToTreat : Libraries to treat
                #                       (symbolic links excluded)
                # ==============================================================

                sub build_library_path
                {
                    my $section     = $_[0];
                    my $searchpath  = $::configPaths{'binary:install'} .'/lib/'.$section;
                    my $searchpath10_5 = '';
                    my $searchpath10_6 = '';
                    my $searchpath10_10 = '';
                    if($section eq 'thirdparty')
                    {
                        $searchpath10_5  = $::configPaths{'binary:install'} .'/lib/'.$section.'/10.5';
                        $searchpath10_6  = $::configPaths{'binary:install'} .'/lib/'.$section.'/10.6';
                        $searchpath10_10  = $::configPaths{'binary:install'} .'/lib/'.$section.'/10.10';
                        # TODO: should we do the same thing for 10.11 ? it doesn't seem to be necessary... so not putting it for now... but to verify. See other similar comment also
                    }
                    my $installpath = '@executable_path/../lib/'.$section;
                    unless(chdir($searchpath))
                    {
                        print "huge problem with $searchpath \n";
                    }
                    my @files = <*>;

                    foreach my $file (@files)
                    {
                        $::libraries{$file} = $installpath.'/'.$file;

                        unless( (-l $searchpath.'/'.$file) | ($file =~ m/\.la$/) )
                        {
                            $::librariesToTreat{$file} = $searchpath.'/'.$file;
                        }
                    }
                    if($searchpath10_5 ne '')
                    {
                        unless(chdir($searchpath10_5))
                        {
                            print "huge problem with $searchpath10_5 \n";
                        }

                        my @files = <*>;

                        foreach my $file (@files)
                        {
                            $::libraries{'10_5'.$file} = $installpath.'/10.5/'.$file;
                            unless( (-l $searchpath10_5.'/'.$file) | ($file =~ m/\.la$/) )
                            {
                                $::librariesToTreat{'10_5'.$file} = $searchpath10_5.'/'.$file;
                            }
                        }
                    }
                    if($searchpath10_6 ne '')
                    {
                        unless(chdir($searchpath10_6))
                        {
                            print "huge problem with $searchpath10_6 \n";
                        }

                        my @files = <*>;

                        foreach my $file (@files)
                        {
                            $::libraries{'10_6'.$file} = $installpath.'/10.6/'.$file;
                            unless( (-l $searchpath10_6.'/'.$file) | ($file =~ m/\.la$/) )
                            {
                                $::librariesToTreat{'10_6'.$file} = $searchpath10_6.'/'.$file;
                            }
                        }
		            }
                    if($searchpath10_10 ne '')
                    {
                        unless(chdir($searchpath10_10))
                        {
                            print "huge problem with $searchpath10_10 \n";
                        }

                        my @files = <*>;

                        foreach my $file (@files)
                        {
                            $::libraries{'10_10'.$file} = $installpath.'/10.10/'.$file;
                            unless( (-l $searchpath10_10.'/'.$file) | ($file =~ m/\.la$/) )
                            {
                                $::librariesToTreat{'10_10'.$file} = $searchpath10_10.'/'.$file;
                            }
                        }
                    }

		    # TODO: should we do the same thing for 10.11 ? it doesn't seem to be necessary... so not putting it for now... but to verify. See other similar comment also

                }

                # ==============================================================
                # get_new_path
                # ==============================================================

                sub get_new_path
                {
                    my $library = $_[0];
                    my $library_basename = basename($library);

                    if( exists($::libraries{$library_basename}) )
                    {
                        return $::libraries{$library_basename};
                    }
                    else
                    {
                        return $library;
                    }
                }

                # ==============================================================
                # get_rpaths
                # ==============================================================

                sub get_rpaths
                {
                    my $library = $_[0];
                    my @libs    = ();
                    # Construction de la commande
                    # ==========================================================
                    my $cmd     = 'otool -L "'.$library.'" |';

                    # Récupération du résultat
                    # ==========================================================
                    open(W,$cmd);

                    while(<W>)
                    {
                        chomp($_);
                        $_ =~ s/^\s+//;
                        $_ =~ s/\s+$//;

                        if($_ =~ m/\:$/ )
                        {
                            next;
                        }

                        my @line = split(/\s/);

                        push(@libs,$line[0]);
                    }

                    close(W);

                    return @libs;
                }

                # Build:
                # + %libraries        : Existing libraries
                #                       (symbolic links included)
                # + %librariesToTreat : Libraries to treat
                #                       (symbolic links excluded)
                # --------------------------------------------------------------

                build_library_path('scilab');
                build_library_path('thirdparty');

                $::librariesToTreat{'scilab-bin'}     = $::configPaths{'binary:install'}.'/bin/scilab-bin';
                $::librariesToTreat{'scilab-cli-bin'} = $::configPaths{'binary:install'}.'/bin/scilab-cli-bin';

                $::libraries{'libxml2.2.dylib'}       = '/usr/lib/libxml2.2.dylib';
                #$::libraries{'libncurses.5.dylib'}    = '/usr/lib/libncurses.5.dylib';

                # Loop on %librariesToTreat
                # --------------------------------------------------------------
                foreach my $library (sort keys %::librariesToTreat)
                {
                    my $fulllib = $::librariesToTreat{$library};

                    if(-f $fulllib)
                    {
                        my @rpaths  = get_rpaths($fulllib);

                        foreach my $rpath (sort @rpaths)
                        {
                            my $old = $rpath;
                            my $new = get_new_path($rpath);
                            log_and_system('install_name_tool -change '.$old.' '.$new.' '.$fulllib);
                        }
                    }
                }

                # Cheats pour dégager les refs sur sw
                #chdir($::configPaths{'binary:install'}.'/lib/scilab');
                #my @libDependingonIntl=<*.dylib*>;
                #foreach my $libDIntl (@libDependingonIntl)
                #{
                #    log_and_system('install_name_tool -change /sw/lib/libintl.3.dylib @executable_path/../lib/thirdparty/libintl.3.dylib '.$libDIntl);
                #}
                # Cheat pour utiliser libintl.8
                #chdir($::configPaths{'binary:install'}.'/lib/thirdparty');
                #system('ln -s libintl.8.dylib libintl.3.dylib');


            }#end of if(is_mac)
            if($::configOS{'is_linux'})
            {
                #
                # On vérifie que les librairies ne contiennent pas de dépendances
                # vers GLIBC > 2.5
                create_message('03410');

                my $so_file_count = 0;
                my $so_bad_count  = 0;

                unless(chdir($::configPaths{'binary:install'}.'/lib'))
                {
                    create_message('03411');
                    return '03411';
                }

                my @so_files = <*/*so*>;

                foreach my $so_file (@so_files)
                {
                    # Cas spécial avec libgomp.so.1, au 2011-03-09
                    #if($so_file =~ 'libgomp.so.1'){
                    #    next;
                    #}
                    if( (-f $so_file) && (! -l $so_file) && (! ($so_file =~ m /la$/ )) )
                    {
                        $so_file_count++;


                        # Construction de la commande
                        my $cmd = 'readelf -V '.$so_file.' 2>&1 |';

                        # Récupération du résultat
                        my $result;

                        open(W,$cmd);
                        while(<W>)
                        {
                            $_ =~ s/^\s+//;
                            $_ =~ s/\s+$/ /; # Replace EOL by spaces to avoid GLIBC_2.1 + 0x0 to be caught as GLIBC_2.10

                            $result .= $_;
                        }
                        close(W);

                        my @GLIBCs = ('GLIBC_2.5' ,
                        'GLIBC_2.6' ,
                        'GLIBC_2.7' ,
                        'GLIBC_2.8' ,
                        'GLIBC_2.9' ,
                        'GLIBC_2.10',
                        'GLIBC_2.11',
                        'GLIBC_2.12',
                        'GLIBC_2.13',
                        'GLIBC_2.14',
                        'GLIBC_2.15',
                        'GLIBC_2.16',
                        'GLIBC_2.17',
                       	'GLIBC_2.18',
                       	'GLIBC_2.19');

                        foreach my $GLIBC (@GLIBCs)
                        {
                            if( index($result,$GLIBC) > -1)
                            {
                                $so_bad_count++;

                                if($so_bad_count == 1)
                                {
                                    create_message('03412',$so_file,$GLIBC);
                                }
                                else
                                {
                                    create_message('03413',$so_file,$GLIBC);
                                }
                            }
                        }

                        if( $result =~ m/readelf: Error:/ )
                        {
                            $so_bad_count++;

                            if($so_bad_count == 1)
                            {
                                create_message('03414',$so_file);
                            }
                            else
                            {
                                create_message('03415',$so_file);
                            }
                        }
                    }
                }
                if($so_bad_count == 0)
                {
                    create_message('03416',$so_file_count);
                }
                else
                {
                    create_message('03417',$so_bad_count,$so_file_count);
                    return '03417';
                }

                # test bug 6942
                create_message('03604');
                my $return_value = `ldd $::configPaths{'binary:install'}/bin/scilab-cli-bin | grep -e "libX"`;
                if ($return_value ne '')
				{
                	create_message('03605',$return_value."\n(Binary location is ".$::configPaths{'binary:install'}.")");
					return '03605';
                }
                else
				{
					create_message('03606');
                }

            }#end of is_linux
            #
            # Définition du répertoire à prendre suivant l'architecture
            #

            my $prerequirements_dir = '';

            if( $::configOS{'is_unix'} )
            {
                if(!defined($::configMain{'skip-archive'}))
                {
                    $prerequirements_dir = $::configPaths{'sources'}.'/Prerequirements/'.$::scilab{'version'};
                }
                else
                {
                    $prerequirements_dir = $::configPaths{'compilation'}.$::sep.$::scilab{'version'};
                }
            }

            # External include files copy
            if( $::configOS{'is_macosx'} )
            {
                # libintl: see bug #4858
                copy($::configSvn{'local'}.'/include/libintl/libintl.h', $::configPaths{'binary'}.'/'.$::scilab{'version'}.'.app/Contents/MacOS/include/');
            }
            if( $::configOS{'is_linux'} )
            {
                # libintl: see bug #4858
                copy($::configSvn{'local'}.'/include/libintl/libintl.h', $::configPaths{'binary'}.'/'.$::scilab{'version'}.'/include/');
            }

            #
            # Thirdparty creation
            #
            if(!$::configMain{'cli'})
            {
                create_message('03229');
                if($::configOS{'is_linux'} && $::configGit{'tag'} ne 'YaSp')
                {
                    # BWidget
                    create_message('03230',$::configPaths{'binary:modules'});
                    unless( copyDir($prerequirements_dir.'/modules/tclsci/tcl/BWidget',$::configPaths{'binary:modules'}) )
                    {
                        create_message('03231',$prerequirements_dir.'/modules/tclsci/tcl/BWidget',$::configPaths{'binary:modules'});
                        return '03231';
                    }

                    # Tcl8
                    unless( copyDir($prerequirements_dir.'/modules/tclsci/tcl/tcl8',$::configPaths{'binary:modules'}) )
                    {
                        create_message('03231',$prerequirements_dir.'/modules/tclsci/tcl/tcl8',$::configPaths{'binary:modules'});
                        return '03231';
                    }

                    # Tcl8.5
                    unless( copyDir($prerequirements_dir.'/modules/tclsci/tcl/tcl8.5',$::configPaths{'binary:modules'}) )
                    {
                        create_message('03231',$prerequirements_dir.'/modules/tclsci/tcl/tcl8.5',$::configPaths{'binary:modules'});
                        return '03231';
                    }

                    # Tk8.5
                    unless( copyDir($prerequirements_dir.'/modules/tclsci/tcl/tk8.5',$::configPaths{'binary:modules'}) )
                    {
                        create_message('03231',$prerequirements_dir.'/modules/tclsci/tcl/tk8.5',$::configPaths{'binary:modules'});
                        return '03231';
                    }

                }
                create_message('03230',$::configPaths{'binary:thirdparty'});

                unless( copyDir($prerequirements_dir.'/thirdparty',$::configPaths{'binary:thirdparty'}) )
                {
                    create_message('03231',$prerequirements_dir.'/thirdparty',$::configPaths{'binary:thirdparty'});
                    return '03231';
                }

                # adds 10.5 folder for mac
                if( $::configOS{'is_macosx'} )
                {
                    chdir($::configSvn{'local'}.'/lib/thirdparty/10.5');
                    my @libs = <*>;
                    foreach my $lib (@libs)
                    {
                        print("copying ".$::directory.'/Dev-Tools/SE/Prerequirements/MacOSX/lib/thirdparty/10.5/'.$lib." to ".$::configPaths{'binary'}.'/'.$::scilab{'version'}.'.app/Contents/MacOS/lib/thirdparty/10.5/');
                        copy($::configSvn{'local'}.'/lib/thirdparty/10.5/'.$lib, $::configPaths{'binary'}.'/'.$::scilab{'version'}.'.app/Contents/MacOS/lib/thirdparty/10.5/');
                    }
                    chdir($::configSvn{'local'}.'/lib/thirdparty/10.6');
                    my @libs = <*>;
                    foreach my $lib (@libs)
                    {
                        print("copying ".$::directory.'/Dev-Tools/SE/Prerequirements/MacOSX/lib/thirdparty/10.6/'.$lib." to ".$::configPaths{'binary'}.'/'.$::scilab{'version'}.'.app/Contents/MacOS/lib/thirdparty/10.6');
                        copy($::configSvn{'local'}.'/lib/thirdparty/10.6/'.$lib, $::configPaths{'binary'}.'/'.$::scilab{'version'}.'.app/Contents/MacOS/lib/thirdparty/10.6/');
                    }
                    chdir($::configSvn{'local'}.'/lib/thirdparty/10.10');
                    my @libs = <*>;
                    foreach my $lib (@libs)
                    {
                        print("copying ".$::directory.'/Dev-Tools/SE/Prerequirements/MacOSX/lib/thirdparty/10.10/'.$lib." to ".$::configPaths{'binary'}.'/'.$::scilab{'version'}.'.app/Contents/MacOS/lib/thirdparty/10.10');
                        copy($::configSvn{'local'}.'/lib/thirdparty/10.10/'.$lib, $::configPaths{'binary'}.'/'.$::scilab{'version'}.'.app/Contents/MacOS/lib/thirdparty/10.10/');
                    }
                    chdir($::configSvn{'local'}.'/lib/thirdparty/10.11');
                    my @libs = <*>;
                    foreach my $lib (@libs)
                    {
                        print("copying ".$::directory.'/Dev-Tools/SE/Prerequirements/MacOSX/lib/thirdparty/10.11/'.$lib." to ".$::configPaths{'binary'}.'/'.$::scilab{'version'}.'.app/Contents/MacOS/lib/thirdparty/10.11');
                        copy($::configSvn{'local'}.'/lib/thirdparty/10.11/'.$lib, $::configPaths{'binary'}.'/'.$::scilab{'version'}.'.app/Contents/MacOS/lib/thirdparty/10.11/');
                    }

                }

                # remove thirdparty/checkstyle which is useless (see bug 3870).

                chdir($::configPaths{'binary:thirdparty'});

                my @items = <checkstyle*>;

                foreach my $item (@items)
                {
                    if( -e $::configPaths{'binary:thirdparty'}.'/'.$item )
                    {
                        rmtree($::configPaths{'binary:thirdparty'}.'/'.$item);

                        if( -e $::configPaths{'binary:thirdparty'}.'/'.$item )
                        {
                            create_message('03232',$::configPaths{'binary:thirdparty'}.'/'.$item);
                            return '03232';
                        }
                    }
                }

                create_message('03233',$::configPaths{'binary:thirdparty'});
            }

            #
            # Inclusion du java
            #

            # don't include Java in windows
            # (in 5.5.2 and before, was is_linux instead of is_unix:
            # but in 6.x we also include the JRE on Mac)
            if($::configOS{'is_unix'} && !$::configMain{'cli'})
            {
                create_message('03240');

                unless( copyDir($prerequirements_dir.'/java/jre',$::configPaths{'binary:thirdparty'}.'/java') )
                {
                    create_message('03241',$prerequirements_dir.'/java/jre',$::configPaths{'binary:thirdparty'}.'/java');
                    return '03241';
                }

                create_message('03242');
            }

            #
            # Inclusion de TclTk: no more usefull since TCL/TK are included in dev-tools
            #

            #if($::configOS{'is_linux'} && !$::configMain{'cli'})
            #{
            #    create_message('03250');
            #
            #    unless( copyDir('/home/scilab/tcltk/tcl8.5',
            #    $::configPaths{'binary'}.'/'.$::scilab{'version'}.'/thirdparty/tcl8.5') )
            #    {
            #        create_message('03251','/home/scilab/tcltk/tcl8.5',$::configPaths{'binary:thirdparty'}.'/tcl8.5');
            #        return '03251';
            #    }
            #
            #    unless( copyDir('/home/scilab/tcltk/tk8.5',
            #    $::configPaths{'binary'}.'/'.$::scilab{'version'}.'/thirdparty/tcl8.5/tk8.5') )
            #    {
            #        create_message('03251','/home/scilab/tcltk/tk8.5',$::configPaths{'binary:thirdparty'}.'/tcl8.5/tk8.5');
            #        return '03251';
            #    }
            #
            #    unless( copyDir('/usr/local/msgcat1.4',
            #    $::configPaths{'binary'}.'/'.$::scilab{'version'}.'/thirdparty/tcl8.5/msgcat1.4') )
            #    {
            #        create_message('03251','/usr/local/msgcat1.4',$::configPaths{'binary:thirdparty'}.'/tcl8.5/msgcat1.4');
            #        return '03251';
            #    }
            #
            #    # remove tk8.5/demos which is useless (see bug 3869).
            #    rmtree($::configPaths{'binary:thirdparty'}.'/tcl8.5/tk8.5/demos');
            #    if( -e $::configPaths{'binary:thirdparty'}.'/tcl8.5/tk8.5/demos' )
            #    {
            #        create_message('03232',$::configPaths{'binary:thirdparty'}.'/tcl8.5/tk8.5/demos');
            #        #return '03232';
            #    }
            #
            #    create_message('03253');
            #}

            if($::configOS{'is_linux'} & !$::configOS{'is_macosx'} )
            {


                #
                # Suppression des .a et .la
                #

                create_message('03260');

                unless( chdir( $::configPaths{'binary:install'}.'/lib/scilab' ) )
                {
                    create_message('03008',$::configPaths{'binary:install'}.'/lib/scilab');
                    return '03008';
                }

                my @la_files = <*.la>;
                my @a_files  = <*.a>;

                if( $#la_files != -1 )
                {
                    unless( unlink <*.la> )
                    {
                        create_message('03262');
                        return '03262';
                    }
                }

                if( $#a_files != -1 )
                {
                    unless( unlink <*.a> )
                    {
                        create_message('03263');
                        return '03263';
                    }
                }

                #
                # Delete .debug files to reduce binary size
                #
                unless( unlink <*.debug> )
                {
                    create_message('03264');
                    return '03264';
                }

            }

            create_message('03264');

            #
            # Modification de bin/scilab
            #
            create_message('03270');

            unless( chmod 0755, $::configPaths{'binary:install'}.'/bin/scilab' )
            {
                create_message('03273',$::configPaths{'binary:install'}.'/bin/scilab');
                return '03273';
            }

            if( -e $::configPaths{'binary:install'}.'/bin/scilab' )
            {
                chdir( $::configPaths{'binary:install'}.'/bin' );

                if( -e $::configPaths{'binary:install'}.'/bin/scilab-cli' )
                {
                    unlink( $::configPaths{'binary:install'}.'/bin/scilab-cli' );
                }

                log_and_system('ln -s scilab scilab-cli');

                if( -e $::configPaths{'binary:install'}.'/bin/scilab-adv-cli' )
                {
                    unlink( $::configPaths{'binary:install'}.'/bin/scilab-adv-cli' );
                }

                log_and_system('ln -s scilab scilab-adv-cli');
            }

            create_message('03274');

            #
            # Modification de fichier etc/classpath.xml et librarypath.xml
            #

            my %xmlfiles;
            $xmlfiles{'classpath.xml'}   = 1;
            $xmlfiles{'librarypath.xml'} = 1;

            foreach my $filetopatch (keys %xmlfiles)
            {
                my $filetoread  = $::configPaths{'binary:install'}.'/share/scilab/etc/'.$filetopatch;
                my $filetowrite = $::configPaths{'binary:install'}.'/share/scilab/etc/'.$filetopatch.'.tmp';

                create_message('03290',$filetoread);

                unless( open( FILETOREAD  , $filetoread ) )
                {
                    create_message('03291',$filetoread);
                    return '03291';
                }

                unless( open( FILETOWRITE  , '> '.$filetowrite ) )
                {
                    create_message('03292',$filetowrite);
                    return '03292';
                }

                while(<FILETOREAD>)
                {
                    $_ =~ s/SCILAB\/thirdparty/SCILAB\/..\/..\/thirdparty/g;
                    $_ =~ s/SCILAB\/bin/SCILAB\/..\/..\/bin/g;
                    $_ =~ s/SCILAB\/lib/SCILAB\/..\/..\/lib\/scilab/g;
                    $_ =~ s/SCILAB\/.libs/SCILAB\/..\/..\/lib\/scilab/g;

                    if( index($_,'../../lib/scilab') != -1 )
                    {
                        print FILETOWRITE '<path value="$SCILAB/../../lib/scilab/"/>'."\n";
                        print FILETOWRITE '<path value="$SCILAB/../../lib/thirdparty/"/>'."\n";
                        next;
                    }

                    if( ($filetopatch eq 'classpath.xml') && (index($_,$::configPaths{'compilation'}.'/'.$::scilab{'version'}.'/thirdparty') != -1) )
                    {
                        my $rep = index($_,$::configPaths{'compilation'}.'/'.$::scilab{'version'}.'/thirdparty');
                        my $len = length($::configPaths{'compilation'}.'/'.$::scilab{'version'}.'/thirdparty');

                        $_ = substr($_,0,$rep).'$SCILAB/../../thirdparty'.substr($_,$rep+$len);
                    }

                    if( $filetopatch eq 'librarypath.xml' )
                    {
                        if( index($_,'SCILAB/modules') != -1 )
                        {
                            next;
                        }
                    }

                    print FILETOWRITE $_;
                }

                close( FILETOREAD );
                close( FILETOWRITE );

                unless( unlink($filetoread) )
                {
                    create_message('03271',$filetoread);
                    return '03271';
                }

                unless( rename($filetowrite,$filetoread) )
                {
                    create_message('03294',$filetowrite,$filetoread);
                    return '03294';
                }

                create_message('03295',$filetoread);
            }

            #
            # Copie des fichiers ACKNOWLEDGEMENTS, CHANGES.md, COPYING, (RELEASE_NOTES), etc.
            #

            my %files_to_copy;
            if($::configGit{'branch'} eq '5.5')
            {
                $files_to_copy{'ACKNOWLEDGEMENTS'}    = 1;
                $files_to_copy{'CHANGES'}             = 1;
                $files_to_copy{'CHANGES_2.X'}         = 1;
                $files_to_copy{'CHANGES_3.X'}         = 1;
                $files_to_copy{'CHANGES_4.X'}         = 1;
                $files_to_copy{'CHANGES_5.0.X'}       = 1;
                $files_to_copy{'CHANGES_5.1.X'}       = 1;
                $files_to_copy{'CHANGES_5.2.X'}       = 1;
                $files_to_copy{'CHANGES_5.3.X'}       = 1;
                $files_to_copy{'CHANGES_5.4.X'}       = 1;
                $files_to_copy{'CHANGES_5.5.X'}       = 1;
                $files_to_copy{'COPYING'}             = 1;
                $files_to_copy{'README_Unix'}         = 1;
                $files_to_copy{'RELEASE_NOTES'}       = 1;
                $files_to_copy{'RELEASE_NOTES_5.0.X'} = 1;
                $files_to_copy{'RELEASE_NOTES_5.1.X'} = 1;
                $files_to_copy{'RELEASE_NOTES_5.2.X'} = 1;
                $files_to_copy{'RELEASE_NOTES_5.3.X'} = 1;
            }
             else
            {
                $files_to_copy{'ACKNOWLEDGEMENTS'}    = 1;
                $files_to_copy{'COPYING'}             = 1;
                $files_to_copy{'CHANGES.md'}          = 1;
                $files_to_copy{'README.md'}           = 1;
            }

            foreach my $file (sort keys %files_to_copy)
            {
                copy(
                $::configPaths{'compilation'}.'/'.$::scilab{'version'}.'/'.$file,
                $::configPaths{'binary:install'}.'/'.$file
                );
            }

            #
            # Suppression de fichiers et répertoires inutiles lorsque l'on
            # construit scilab en moteur de calcul
            #

            if($::configMain{'cli'})
            {
                create_message('03500');

                my $modules_path = $::configPaths{'binary:install'}.'/share/scilab/modules';
                my %notneeded_modules;

                $notneeded_modules{'graphics'}         = 1;
                $notneeded_modules{'graphic_export'}   = 1;
                $notneeded_modules{'renderer'}         = 1;
                $notneeded_modules{'helptools'}        = 1;
                $notneeded_modules{'gui'}              = 1;
                $notneeded_modules{'jvm'}              = 1;
                $notneeded_modules{'javasci'}          = 1;
                $notneeded_modules{'tclsci'}           = 1;
                $notneeded_modules{'scipad'}           = 1;
                $notneeded_modules{'demo_tools'}       = 1;
                $notneeded_modules{'scicos'}           = 1;

                # Déplacement dans le répertoire des modules
                unless(chdir($modules_path))
                {
                    create_message('03501',$modules_path);
                    return '03501';
                }

                # Récupération de la liste des modules
                my @modules = <*>;

                foreach my $module (@modules)
                {
                    if( (-d $modules_path.'/'.$module) && (-e $modules_path.'/'.$module.'/etc/'.$module.'.start') )
                    {
                        my $module_directory = $modules_path.'/'.$module;

                        # remove demos
                        if(-d $module_directory.'/demos')
                        {
                            rmtree($module_directory.'/demos');
                        }

                        # This module is not needed
                        if( exists($notneeded_modules{$module}) )
                        {
                            # remove tests
                            rmtree($module_directory.'/tests');
                        }
                    }
                }

                create_message('03502');
            }
		}
		# END OF IS_UNIX

		#
	    # Installation des modules atoms demandés
	    #

		#if(%::atomsModules)
		if(%::configATOMS || %::configSourcesATOMS)
		{
			my $tool = '';
			my $filetowrite = $::configPaths{'log'}.'add_modules.sce';
			if($::configOS{is_unix}){
				$tool = 'wget';
			}
			else{
				$tool = 'curl';
			}

			unless( open( FILETOWRITE  , '> '.$filetowrite ) )
			{
				create_message('03292',$filetowrite);
				return '03292';
			}
			#Modules from the portal
			if(%::configATOMS)
			{
				print FILETOWRITE 'atomsSetConfig("offLine","False");'."\n";
				foreach my $mod (keys(%::configATOMS))
				{
					# Get the package
					print FILETOWRITE 'atomsInstall("'.$mod.'");'."\n";
					#print FILETOWRITE 'atomsInstall(["'.$mod.'" ';
					#if($::atomsModules{$mod} ne ''){
					#	print FILETOWRITE ' "'.$::atomsModules{$mod}.'"';
					#}
					#print FILETOWRITE ']);'."\n";
				}
			}
			#Modules from sources
			if(%::configSourcesATOMS)
			{
				print FILETOWRITE 'atomsSetConfig("offLine","True");'."\n";
				foreach my $mod (keys(%::configSourcesATOMS))
				{
					# Get the package
					print FILETOWRITE 'atomsInstall("'.$::configSourcesATOMS{$mod}.'");'."\n";
					#print FILETOWRITE 'atomsInstall(["'.$mod.'" ';
					#if($::atomsModules{$mod} ne ''){
					#	print FILETOWRITE ' "'.$::atomsModules{$mod}.'"';
					#}
					#print FILETOWRITE ']);'."\n";
				}
			}
			print FILETOWRITE 'atomsSetConfig("offLine","False");'."\n";
			print FILETOWRITE 'quit;'."\n";
			close(FILETOWRITE);
			my $scilabCmd;
			if($::configOS{'is_unix'})
			{
				$scilabCmd  = $::configPaths{'binary'}.$::sep.$::scilab{'version'}.$::sep.'bin'.$::sep.$::configMain{'scilab_mode'};
			}
			else
			{
				$scilabCmd  = $::configPaths{'compilation'}.$::sep.$::scilab{'version'}.$::sep.'bin'.$::sep.$::configMain{'scilab_mode'};
			}
			$scilabCmd .= ' -nw -nb -f "'.$filetowrite.'"';
			$scilabCmd .= ' > '.$::files{'log:binary:add_modules.txt'}.' 2>&1';		my $tool = '';
			$returnCode = log_and_system($scilabCmd);
	    }


		if($::configOS{'is_unix'}){
            #
            # Construction de l'archive tar.gz ou dmg
            #

            create_message('03280');
            create_message('03281',$::files{'binary:archive_scilab'});

            unless( chdir($::configPaths{'binary'}) )
            {
                create_message('03008',$::configPaths{'binary'});
                return '03008';
            }

            if( ! $::configOS{'is_macosx'} )
            {
                #
                # TAR
                #

                $returnCode = log_and_system("tar vcf $::files{'binary:archive_scilab_tar'} $::scilab{'version'} > $::files{'log:binary:targzbin.txt'} 2>&1");

                if($returnCode != 0)
                {
                    create_message('03283',$::scilab{'version'});
                    return '03283';
                }

                #
                # GZIP
                #

                $returnCode = log_and_system("gzip -f $::files{'binary:archive_scilab_tar'} >> $::files{'log:binary:targzbin.txt'} 2>&1");

                #
                # TODO: publish XZ version to reduce download bandwidth
                #
                # $returnCode = log_and_system("xz -f -9 -- $::files{'binary:archive_scilab_tar'} >> $::files{'log:binary:targzbin.txt'} 2>&1");

                if($returnCode!=0)
                {
                    create_message('03284',$::scilab{'version'});
                    return '03284';
                }
            }
            else
            {
                ## DMG CREATION
                unlink $::scilab{'version'}.".dmg";

                # Création d'un "joli" dmg pour les releases, les master et les branches
                if($::configMain{'version_type'} eq 'release' || $::configGit{'tag'} eq 'YaSp' || $::configGit{'branch'} eq 'master' || $::configGit{'branch'} eq '6.0'){
                    my $dmgcreation = $::configPaths{'tools'}."/yoursway-create-dmg/create-dmg --window-size 381 290 --background ".$::configPaths{'tools'};

                    # select the right background image
                    my $background = '';
                    if($::configMain{'version_type'} eq 'release') {
                        # Image to be customized for each release
                        $background = "/install_mac_".$::scilab{'version'}.".png"
                    }
                    else {
                        $background = "/install_mac_".$::configGit{'branch'}.".png";
                    }

                    $dmgcreation .= $background;
                    if($::configMain{'version_type'} ne 'release'){
                        $dmgcreation .= " --release-notes ".$::configPaths{'binary'}."/".$::scilab{'version'}.".app/Contents/MacOS/CHANGES.md 420 105 ";
                    }
                    else{
                        # uncomment to use the CHANGES.html file if the pdf
                        # is not ready
                        #dmgcreation .= " --release-notes ".$::configPaths{'binary'}."/".$::scilab{'version'}.".app/Contents/MacOS/share/scilab/modules/helptools/data/pages/CHANGES.html 420 105 ";
                        #$dmgcreation .= " --release-notes ".$::configPaths{'tools'}."/../ini/Scilab6.0.0_ReleaseNotes.pdf 420 105 "; ## PDF to be customized for each release
                    }
                    #$dmgcreation .= " --copying ".$::configPaths{'binary'}."/".$::scilab{'version'}.".app/Contents/MacOS/COPYING 420 205 ";
                    $dmgcreation .= ' --icon-size 48 --volname "'.$::scilab{'version'}.'" ';
                    $dmgcreation .= ' --app-drop-link 280 105 ';
                    $dmgcreation .= ' --icon "'.$::scilab{'version'}.'.app" 100 105 ';
                    $dmgcreation .= ' '.$::files{'binary:archive_scilab'};
                    $dmgcreation .= ' '.$::configPaths{'binary'}.'/'.$::scilab{'version'}.'.app';
                    if(log_and_system($dmgcreation.' > '.$::files{'log:binary:targzbin.txt'}.' 2>&1') ){
	                    create_message('03283',$::scilab{'version'});
        	            return '03283';
                    }
                }
                # dmg normal sinon
                else{
	                if( system('hdiutil create -verbose -srcfolder '.$::configPaths{'binary'}.' -volname '.$::scilab{'version'}.' '.$::files{'binary:archive_scilab'}.' > '.$::files{'log:binary:targzbin.txt'}.' 2>&1') )
	                {
        	            create_message('03283',$::scilab{'version'});
                	    return '03283';
                    }
                }

                #
                # Sign the dmg
                #
                # The SuperCC keychain contains the "3rd Party Mac Developer Application: SCILAB ENTERPRISES (M9A7TMQ5QQ)" use it !
                # Otherwise start by unlocking the user keychain to make it usable via ssh
                if( system('codesign -s "SCILAB ENTERPRISES" --keychain "/Users/scilab/Library/Keychains/SuperCC.keychain" '.$::files{'binary:archive_scilab'}.' --deep 2>&1') )
                {
                    create_message('03324',$::files{'binary:archive_scilab'});
                }
                else
                {
                    create_message('03325');
                }
            }

            #
            # VERIF
            #

            if(-e $::files{'binary:archive_scilab'} )
            {
                create_message('03285',basename($::files{'binary:archive_scilab'}),$::configPaths{'save'});
                create_message('03286');
            }
            else
            {
                create_message('03287',basename($::files{'binary:archive_scilab'}),$::configPaths{'save'});
                return '03287';
            }

        }
        # ===============================================
        # End of tarball/dmg creation
        # ===============================================


        # ======================================================================
        # Création du binaire scilab
        # ======================================================================

        if( $::configOS{'is_windows'} )
        {
            my $sci_iss_from_dir  = $::configPaths{'compilation'}.$::sep.$::scilab{'version'}.$::sep.'tools'.$::sep.'innosetup';
            my $sci_iss_to_dir    = $::configPaths{'binary'}.$::sep.'sci_iss';
            my $create_iss_script;

            if($::configMain{'embed_jre'} eq 'yes')
            {
                $create_iss_script = $sci_iss_to_dir.$::sep.'Create_ISS.sce';
            }
            else
            {
                $create_iss_script = $sci_iss_to_dir.$::sep.'Create_ISS_nojre.sce';
            }

            #
            # Copie du répertoire contenant le iss dans un répertoire temporaire
            #

            create_message('03023',$sci_iss_to_dir);
            unless( copyDir($sci_iss_from_dir,$sci_iss_to_dir) )
            {
                create_message('03024',$sci_iss_from_dir,$sci_iss_to_dir);
                return '03024';
            }
            create_message('03025');

            #
            # Première étape : génération de scilab.iss
            #

            create_message('03026');

            my $scilabCmd;
            $scilabCmd  = $::configPaths{'compilation'}.$::sep.$::scilab{'version'}.$::sep.'bin'.$::sep.$::configMain{'scilab_mode'};
            $scilabCmd .= ' -nw -nb -f "'.$create_iss_script.'"';
            $scilabCmd .= ' > '.$::files{'log:binary:create_iss.txt'}.' 2>&1';

            $returnCode = log_and_system($scilabCmd);

            if( -f $sci_iss_to_dir.$::sep.'Scilab.iss' )
            {
                create_message('03027');
            }
            else
            {
                create_message('03028');
                return '03028';
            }

            #
            # Seconde étape : Création du binaire
            #

            create_message('03029');

            unless( chdir($::configPaths{'compilation'}.$::sep.$::scilab{'version'}) )
            {
                create_message('03030',$::configPaths{'compilation'}.$::sep.$::scilab{'version'});
            }

            $returnCode=log_and_system("iscc Scilab.iss > $::files{'log:binary:iss.txt'} 2>&1");

            if($returnCode != 0)
            {
                create_message('03031');
                return '03031';
            }

            create_message('03032');

            #
            # Troisième étape : Déplacement du binaire dans le répertoire de sauvegarde
            #

            create_message('03033');

            unless( move( $::configPaths{'compilation'}.$::sep.$::scilab{'version'}.$::sep.'Output'.$::sep.basename($::files{'binary:archive_scilab'}), $::configPaths{'save'}.$::sep.basename($::files{'binary:archive_scilab'}) ) )
            {
                create_message('03034',basename($::files{'binary:archive_scilab'}),$::configPaths{'save'});
                return '03034';
            }

            if(-e $::configPaths{'save'}.$::sep.basename($::files{'binary:archive_scilab'}))
            {
                create_message('03035',basename($::files{'binary:archive_scilab'}),$::configPaths{'save'});
            }
            else
            {
                create_message('03036',basename($::files{'binary:archive_scilab'}),$::configPaths{'save'});
                return '03036';
            }
        }# END OF IS_WINDOWS

		# ======================================================================
		# Si windows, signature du binaire par l'autorité windows
		# ======================================================================
		if($::configOS{'is_windows'}){
			create_message('03610');
			my $signtool;
			if(-e 'C:\Program Files\Windows Kits\8.1\bin' || -e 'C:\Program Files (x86)\Windows Kits\8.1\bin')
			{
				if($::configOS{'is_64'})
				{
					$signtool = '"C:\Program Files (x86)\Windows Kits\8.1\bin\x64\signtool.exe"';
				}
				else
				{
					$signtool = '"C:\Program Files\Windows Kits\8.1\bin\x86\signtool.exe"';
				}
			}
			elsif(-e 'C:\Program Files\Windows Kits\8.0' || -e 'C:\Program Files (x86)\Windows Kits\8.0')
			{
				if($::configOS{'is_64'})
				{
					$signtool = '"C:\Program Files (x86)\Windows Kits\8.0\bin\x64\signtool.exe"';
				}
				else
				{
					$signtool = '"C:\Program Files\Windows Kits\8.0\bin\x86\signtool.exe"';
				}
			}
			else # windows < 8
			{
				if($::configOS{'is_64'})
				{
					$signtool = 'C:\WinDDK\7600.16385.1\bin\x86\SignTool.exe';
				}
				elsif($::configOS{'is_32'})
				{
					$signtool = '"C:\Program Files\Microsoft SDKs\Windows\v7.0A\bin\signtool.exe"';
				}
			}

			# my $cmd = $signtool." sign /f D:\\scilab.pfx /p scilab /t http://timestamp.verisign.com/scripts/timestamp.dll /v ".$::configPaths{'save'}.'\\'.basename($::files{'binary:archive_scilab'});
			my $cmd = $signtool." sign /f D:\\ESIGroupCERT.pfx /p G3t1tR1ght\@ESI /t http://timestamp.verisign.com/scripts/timestamp.dll /v ".$::configPaths{'save'}.'\\'.basename($::files{'binary:archive_scilab'});
			if(	log_and_system($cmd) == 0)
			{
				create_message('03612');
			}
			else
			{
				create_message('03613',$?);
			}
		}

        # ======================================================================
        # Ajout de la signature électronique pour le binaire scilab
        # ======================================================================

        create_message('03037');

        # Création du fichier md5.txt pour les binaires
        # $type = (linux, linuxDebug, windows, ...)

        my $md5_bin;
        my $md5_bin_target;

        $::file{'binary:md5_archive_scilab'} = $::configPaths{'save'}
        .$::sep."md5_"
        .$::scilab{'version'};
        if( $::configOS{'is_64'} )
        {
            $::file{'binary:md5_archive_scilab'} .= '_'.$::configOS{'arch_symbol'};
        }
        $::file{'binary:md5_archive_scilab'} .= "_".$::configOS{'name'}.".bin.txt";

        $md5_bin        = digest_file_hex($::files{'binary:archive_scilab'},"MD5");
        $md5_bin_target = basename($::files{'binary:archive_scilab'});

        open(MD5,'> '.$::file{'binary:md5_archive_scilab'});
        print MD5 "$md5_bin $md5_bin_target";
        close MD5;

        create_message('03038',$md5_bin_target,$md5_bin);

        # ======================================================================
        # Création du binaire MKL
        # ======================================================================

        if( $::configOS{'is_windows'} && ($::configFftwmkl{'mkl_support'} eq 'yes') )
        {
            my $archi;

            if( $::configOS{'is_64'} )
            {
                $archi      = 'x64';
                $::files{'binary:MKL'} = 'MKL-for-'.$::scilab{'version'}.'_'.$archi.'.exe';
            }
            else
            {
                $archi      = 'x86';
                $::files{'binary:MKL'} = 'MKL-for-'.$::scilab{'version'}.'.exe';
            }

            my $mkl_from_dir = $::configPaths{'Dev-Tools'}.$::sep.'OTHERS'.$::sep.'MKL'.$::sep.'windows'.$::sep.$archi;
            my $mkl_to_dir   = $::configPaths{'binary'}.$::sep.'MKL';

            #
            # Copie du répertoire contenant le iss dans un répertoire temporaire
            #

            create_message('03043',$mkl_to_dir);
            unless( copyDir($mkl_from_dir,$mkl_to_dir) )
            {
                create_message('03044',$mkl_from_dir,$mkl_to_dir);
                return '03044';
            }
            create_message('03047');

            #
            # Première étape : génération de MKL.iss
            #

            create_message('03048');

            my $scilabCmd;
            $scilabCmd  = $::configPaths{'compilation'}.$::sep.$::scilab{'version'}.$::sep.'bin'.$::sep.$::configMain{'scilab_mode'};
            $scilabCmd .= ' -nwni -nb -f "'.$mkl_to_dir.$::sep.'Create_ISS_MKL.sce"';
            $scilabCmd .= ' > '.$::files{'log:binary:create_iss_mkl.txt'}.' 2>&1';

            $returnCode = log_and_system($scilabCmd);

            if( -f $mkl_to_dir.$::sep.'MKL.iss' )
            {
                create_message('03049');
            }
            else
            {
                create_message('03050');
                return '03050';
            }

            #
            # Seconde étape : Création du binaire
            #

            create_message('03051');

            unless( chdir($mkl_to_dir) )
            {
                create_message('03052',$mkl_to_dir);
            }

            $returnCode=log_and_system("iscc MKL.iss > $::files{'log:binary:iss_mkl.txt'} 2>&1");
            if($returnCode != 0)
            {
                create_message('03053');
                return '03053';
            }

            create_message('03054');

            #
            # Troisième étape : Déplacement du binaire dans le répertoire de sauvegarde
            #

            create_message('03055');

            unless( move( $mkl_to_dir.$::sep.'Output'.$::sep.$::files{'binary:MKL'} , $::configPaths{'save'}.$::sep.$::files{'binary:MKL'} ) )
            {
                create_message('03056',$::files{'binary:MKL'},$::configPaths{'save'});
                return '03056';
            }

            if(-e $::configPaths{'save'}.$::sep.$::files{'binary:MKL'})
            {
                create_message('03057',$::files{'binary:MKL'},$::configPaths{'save'});
            }
            else
            {
                create_message('03058',$::files{'binary:MKL'},$::configPaths{'save'});
                return '03058';
            }

            # ==================================================================
            # Ajout de la signature électronique pour le binaire MKL
            # ==================================================================

            create_message('03059');

            # Création du fichier md5.txt pour les binaires
            # $type = (linux, linuxDebug, windows, ...)

            my $mkl_md5_bin;
            my $mkl_md5_bin_target;

            $::file{'binary:md5_MKL'} = $::configPaths{'save'}
            ."\md5_MKL-for-"
            .$::scilab{'version'};
            if( $::configOS{'is_64'} )
            {
                $::file{'binary:md5_MKL'} .= '_'.$::configOS{'arch_symbol'};
            }
            $::file{'binary:md5_MKL'} .= "_".$::configOS{'name'}.".bin.txt";

            $mkl_md5_bin        = digest_file_hex($::configPaths{'save'}.$::sep.$::files{'binary:MKL'},"MD5");
            $mkl_md5_bin_target = $::files{'binary:MKL'};

            open(MD5,'> '.$::file{'binary:md5_MKL'});
            print MD5 $mkl_md5_bin.' '.$mkl_md5_bin_target;
            close MD5;

            create_message('03060',$mkl_md5_bin_target,$mkl_md5_bin);

            $::files{'binary:MKL'} = $::configPaths{'save'}.$::sep.$::files{'binary:MKL'};
            export_state();
        }

        # ======================================================================
        # Création du binaire FFTW
        # ======================================================================

        if( $::configOS{'is_windows'} && ($::configFftwmkl{'fftw_support'} eq 'yes') )
        {
            my $archi;

            if( $::configOS{'is_64'} )
            {
                $archi      = 'x64';
                $::files{'binary:FFTW'} = 'FFTW-for-'.$::scilab{'version'}.'_'.$archi.'.exe';
            }
            else
            {
                $archi      = 'x86';
                $::files{'binary:FFTW'} = 'FFTW-for-'.$::scilab{'version'}.'.exe';
            }

            my $fftw_from_dir = $::configPaths{'Dev-Tools'}.$::sep.'OTHERS'.$::sep.'fftw'.$::sep.'windows'.$::sep.$archi;
            my $fftw_to_dir   = $::configPaths{'binary'}.$::sep.'fftw';

            #
            # Copie du répertoire contenant le iss dans un répertoire temporaire
            #

            create_message('03070',$fftw_to_dir);
            unless( copyDir($fftw_from_dir,$fftw_to_dir) )
            {
                create_message('03072',$fftw_from_dir,$fftw_to_dir);
                return '03072';
            }
            create_message('03074');

            #
            # Première étape : génération de FFTW.iss
            #

            create_message('03075');

            my $scilabCmd;
            $scilabCmd  = $::configPaths{'compilation'}.$::sep.$::scilab{'version'}.$::sep.'bin'.$::sep.$::configMain{'scilab_mode'};
            $scilabCmd .= ' -nwni -nb -f "'.$fftw_to_dir.$::sep.'Create_ISS_FFTW.sce"';
            $scilabCmd .= ' > '.$::files{'log:binary:create_iss_fftw.txt'}.' 2>&1';

            $returnCode = log_and_system($scilabCmd);

            if( -f $fftw_to_dir.$::sep.'FFTW.iss' )
            {
                create_message('03076');
            }
            else
            {
                create_message('03077');
                return '03077';
            }

            #
            # Seconde étape : Création du binaire
            #

            create_message('03078');

            unless( chdir($fftw_to_dir) )
            {
                create_message('03079',$fftw_to_dir);
            }

            $returnCode=log_and_system("iscc FFTW.iss > $::files{'log:binary:iss_fftw.txt'} 2>&1");
            if($returnCode != 0)
            {
                create_message('03080');
                return '03053';
            }

            create_message('03081');

            #
            # Troisième étape : Déplacement du binaire dans le répertoire de sauvegarde
            #

            create_message('03082');

            unless( move( $fftw_to_dir.$::sep.'Output'.$::sep.$::files{'binary:FFTW'} , $::configPaths{'save'}.$::sep.$::files{'binary:FFTW'} ) )
            {
                create_message('03083',$::files{'binary:FFTW'},$::configPaths{'save'});
                return '03083';
            }

            if(-e $::configPaths{'save'}.$::sep.$::files{'binary:FFTW'})
            {
                create_message('03084',$::files{'binary:FFTW'},$::configPaths{'save'});
            }
            else
            {
                create_message('03085',$::files{'binary:FFTW'},$::configPaths{'save'});
                return '03085';
            }

            # ==================================================================
            # Ajout de la signature électronique pour le binaire FFTW
            # ==================================================================

            create_message('03086');

            # Création du fichier md5.txt pour les binaires
            # $type = (linux, linuxDebug, windows, ...)

            my $fftw_md5_bin;
            my $fftw_md5_bin_target;

            $::file{'binary:md5_FFTW'} = $::configPaths{'save'}
            ."\md5_FFTW-for-"
            .$::scilab{'version'};
            if( $::configOS{'is_64'} )
            {
                $::file{'binary:md5_FFTW'} .= '_'.$::configOS{'arch_symbol'};
            }
            $::file{'binary:md5_FFTW'} .= "_".$::configOS{'name'}.".bin.txt";

            $fftw_md5_bin        = digest_file_hex($::configPaths{'save'}.$::sep.$::files{'binary:FFTW'},"MD5");
            $fftw_md5_bin_target = basename($::configPaths{'save'}.$::sep.$::files{'binary:FFTW'});

            open(MD5,'> '.$::file{'binary:md5_FFTW'});
            print MD5 "$fftw_md5_bin $fftw_md5_bin_target";
            close MD5;

            create_message('03087',$fftw_md5_bin_target,$fftw_md5_bin);


            $::files{'binary:FFTW'} = $::configPaths{'save'}.$::sep.$::files{'binary:FFTW'};
            export_state();
        }
    }
    elsif($::configMain{'bin_from_server'} eq 'yes')
    {
        $returnCode = get_bin();
        if($returnCode != 0)
        {
            return $returnCode;
        }
    }

    # If it's a release, add the fileflag so that the server will copy it
    # in the right folder, and create pages from it

    if($::configMain{'version_type'} eq 'release')
    {
        # making it a very unique name, just being paranoid about it being overwritten by another build...
        my $flagfile = $::configPaths{'log'}.$::sep.'flagrelease-'.$::configMain{'version_imposedName'}.'-'.$::configOS{'name'}.$::configOS{'arch'}.'-'.$::configGit{'timestamp'}.'.php';
        open(FLAGFILE,'> '.$flagfile);
        print FLAGFILE '<?php '."\n";
        print FLAGFILE '$name = \''.$::configMain{'version_imposedName'}."';\n";
        my $shortname = $::configMain{'version_imposedName'};
        $shortname =~ s/scilab\-//;
        my $title = $::configMain{'version_imposedName'};
        $title = join(' ', split('-',$::configMain{'version_imposedName'}));
        $title =~ s/(\w+)/\u$1/g;
        print FLAGFILE '$shortname = \''.$shortname."';\n";
        print FLAGFILE '$title = \''.$title."';\n";
        print FLAGFILE '$OS = \''.$::configOS{'name'}."';\n";
        if($::configOS{'is_32'})
        {
            print FLAGFILE '$arch = \'32\';'."\n";
        }
        else
        {
            print FLAGFILE '$arch = \'64\';'."\n";
        }
        if($::configGit{'timestamp'}){
            print FLAGFILE '$publish_date = \''.$::configGit{'timestamp'}."';\n";
        }
        else{
            print FLAGFILE '$publish_date = \''.$::date->middaytimestamp()."';\n";
        }
        my $md5sum = digest_file_hex($::files{'binary:archive_scilab'},"MD5");
        my $sha1sum = digest_file_hex($::files{'binary:archive_scilab'},"SHA-1");
        print FLAGFILE '$filename = \''.basename($::files{'binary:archive_scilab'})."';\n";
        print FLAGFILE '$fileurl = \'http://www.scilab.org/download/'.$shortname.'/'.basename($::files{'binary:archive_scilab'})."';\n";
        print FLAGFILE '$md5sum = \''.$md5sum."';\n";
        print FLAGFILE '$sha1sum = \''.$sha1sum."';\n";
        print FLAGFILE '$filesize = \''. stat($::files{'binary:archive_scilab'})->size."';\n";

        $md5sum = digest_file_hex($::files{'sources:archive_prerequirements'},"MD5");
        $sha1sum = digest_file_hex($::files{'sources:archive_prerequirements'},"SHA-1");
        print FLAGFILE '$prerequirementsfilename = \''.basename($::files{'sources:archive_prerequirements'})."';\n";
        print FLAGFILE '$prerequirementsfileurl = \'http://www.scilab.org/download/'.$shortname.'/'.basename($::files{'sources:archive_prerequirements'})."';\n";
        print FLAGFILE '$prerequirementsmd5sum = \''.$md5sum."';\n";
        print FLAGFILE '$prerequirementssha1sum = \''.$sha1sum."';\n";
        print FLAGFILE '$prerequirementsfilesize = \''. stat($::files{'sources:archive_prerequirements'})->size."';\n";
        if($::configOS{'is_32'} || $::configOS{'is_macosx'}){
            $md5sum = digest_file_hex($::files{'sources:archive_scilab'},"MD5");
            $sha1sum = digest_file_hex($::files{'sources:archive_scilab'},"SHA-1");

            print FLAGFILE '$sourcefilename = \''.basename($::files{'sources:archive_scilab'})."';\n";
            print FLAGFILE '$sourcefileurl = \'http://www.scilab.org/download/'.$shortname.'/'.basename($::files{'sources:archive_scilab'})."';\n";
            print FLAGFILE '$sourcemd5sum = \''.$md5sum."';\n";
            print FLAGFILE '$sourcesha1sum = \''.$sha1sum."';\n";
            print FLAGFILE '$sourcefilesize = \''. stat($::files{'sources:archive_scilab'})->size."';\n";
        }
        print FLAGFILE '?>';
        close(FLAGFILE);

        send_scp_txt_files
        (
            $::configPaths{'FTP'},
            $flagfile
        );
    }

    # Stage successfully finished
    # ==========================================================================
    return 0;
}



# ==============================================================================
# Author : Pierre MARECHAL
# Date : 04 fev 2005
#
# Récupérer le binaire depuis /home/qualif/compilationChain/"date"
#
# Si tout s'est bien déroulé, la fonction retourne 0,
# sinon, elle retourne 414 ou 415
#
# ==============================================================================

sub get_bin
{
    create_message('03100');

    my @filesToGet = ();

    push(@filesToGet,basename($::files{'binary:archive_scilab'}));

    if( $::configOS{'is_windows'}
    && ($::configFftwmkl{'fftw_support'} eq 'yes') )
    {
        if( $::configOS{'is_64'} )
        {
            $::files{'binary:FFTW'} = $::configPaths{'save'}.$::sep.'FFTW-for-'.$::scilab{'version'}.'_x64.exe';
        }
        else
        {
            $::files{'binary:FFTW'} = $::configPaths{'save'}.$::sep.'FFTW-for-'.$::scilab{'version'}.'.exe';
        }

        push(@filesToGet,basename($::files{'binary:FFTW'}));
        export_state();
    }

    if( $::configOS{'is_windows'}
    && ($::configFftwmkl{'fftw_support'} eq 'yes') )
    {
        if( $::configOS{'is_64'} )
        {
            $::files{'binary:MKL'} = $::configPaths{'save'}.$::sep.'MKL-for-'.$::scilab{'version'}.'_x64.exe';
        }
        else
        {
            $::files{'binary:MKL'} = $::configPaths{'save'}.$::sep.'MKL-for-'.$::scilab{'version'}.'.exe';
        }

        push(@filesToGet,basename($::files{'binary:MKL'}));
        export_state();
    }

    unless( chdir($::configPaths{'save'}) )
    {
        create_message('03101',$::configPaths{'save'});
        return '03101';
    }

    my $ftp = Net::FTP->new($::configFtp{'server'},
    Debug => 0 ,
    Port => $::configFtp{'port'},
    Passive => 1 );

    my $iError=$ftp->login($::configFtp{'login'},
    $::configFtp{'password'});

    if( $iError == 1 )
    {
        $ftp->binary();
        $ftp->cwd($::configFtp{'path'}.$::sep.'versions'.$::sep.$::configFtp{'saveDirectory'});

        foreach my $file (@filesToGet)
        {
            $ftp->get($file);
        }
    }
    else
    {
        create_message('03102',$::files{'binary:archive_scilab'});
        return '03102';
    }

    $ftp->quit;


    foreach my $file (@filesToGet)
    {
        unless(-e $file)
        {
            create_message('03104',$::configPaths{'save'});
            return '03104';
        }
    }

    create_message('03103',$::configPaths{'save'});


    export_state();



    return 0;
}
