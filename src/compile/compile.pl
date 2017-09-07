#!/usr/bin/perl
#use Cwd;
sub CompileAll(){
    local($dir) = @_;
    opendir(DIR,"$dir"|| die "can't open $dir");
    local @files =readdir(DIR);
    closedir(DIR);
    for $file (@files){
        next if($file=~m/\.$/ || $file =~m/\.\.$/);
        if ($file =~/\.(c|cpp)$/i){
            $file2=$file;
            $file =~ s/(.*)\.(.*)/$1/;
            system "gcc \"$dir\/$file2\" -o \"$dir\/$file\"";
        }
        elsif(-d "$dir/$file"){
            CompileAll("$dir/$file" );
        }
    }
}
&CompileAll(getcwd);