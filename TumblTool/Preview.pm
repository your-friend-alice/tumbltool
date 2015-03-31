use strict;
#use warnings;
package TumblTool::Preview;
use URI::Escape;
use CSS::Minifier;
use JavaScript::Minifier;
use TumblTool::PathUtils;
use TumblTool::Slurp;
use TumblTool::Include;
use TumblTool::TumblrVar;
use Data::Dumper;
use base 'Exporter';
our @EXPORT=('render');
my $includes=[];
my $strip=0;
my $contentRoot='';
sub configure
{
	my $options=shift();
	$includes    = $options->{"includes"   } // $includes;
	$strip       = $options->{"strip"      } // $strip;
	$contentRoot = $options->{"contentRoot"} // $contentRoot;
}
sub render #render a demo using $content for filler text, etc
{
	(my $block, my $content)=@_;
	$content=specialCases($content);
	my $result="";
	foreach my $item (@{$block}) {
		if(ref($item) eq "HASH") {
			$result.=renderBlock($item, $content);
		}
		elsif(!($item=~/^[\r\n\s]*$/)){ #don't concatenate if it's just a blank line; that's leftovers from block declarations. TODO: maybe this should be dealt with in the parse function???
			$result.=$item;
		}
	}
	return $result;
}
sub renderBlock #used by render to do most of the heavy lifting
{
	(my $block, my $content)=@_;
	if($block->{"children"} and $content->{$block->{"name"}}) { #If the block has children, it's not just a var, it's a block. Check if there is anything to go in the block, and if so, render it.
		if(ref($content->{$block->{"name"}}) eq "ARRAY") {#Is the relevant content an array (eg. posts, tags, etc)?
			my $result="";
			foreach my $contentItem (@{$content->{$block->{"name"}}}) { #iterate over said array
				$result.=render($block->{"children"}, $contentItem); #render the current block for each array item
			}
			return $result;
		}
		else { #No it's not an array; thank goodness. Just render it
			return render($block->{"children"}, $content);
		}
	}
	else { #since it's not a block, it's a placeholder.
		my $result="";
		if($block->{"name"} eq "tumbltool_includes") {
			$result=processIncludes($includes);
		}
		else {
			$result=printVar($block, $content);
		}
		return (($result eq "1")?"":$result); #if the text is just "1" don't print anything though
	}
}
sub specialCases
{
	(my $content)=@_;
	$content->{ucfirst($content->{"PostType"})}=1 if($content->{"PostType"});
	$content->{"Twitter"}=1 if($content->{"TwitterUsername"});
	return($content);
}
1;
