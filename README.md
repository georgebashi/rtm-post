# RTM Post

This is a little script to post tasks to [Remember the Milk](https://www.rememberthemilk.com).

You'll need to set the environment variables `RTM_API_KEY` and `RTM_SHARED_SECRET`, which you can get from [RTM's API key signup page](https://www.rememberthemilk.com/services/api/keys.rtm). You'll also need [jq](http://stedolan.github.io/jq/) installed. Oh, and I do URL encoding with python, but any version should be fine.

Once you've got all that, just run:

```
./rtm-post.sh 'buy @georgebashi a beer'
```

I have this aliased as `r` for convenience. I also have a simple Alfred workflow for chucking tasks into my RTM inbox.

Also handy is putting this in scripts to make them automatically set you reminders for clean-up tasks. The script is small and simple enough to just drop in your dotfiles if you're into that.


