# Instagram Basic Display

This is a client gem for Instagram’s [Basic Display API](https://developers.facebook.com/docs/instagram-basic-display-api/). It’s a small wrapper around the API that provides access to users’ media and profile information. Not every endpoint has been implemented, so pull requests are welcome to round things out!

Updates to the documentation are also very welcome!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'instagram_basic_display'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install instagram_basic_display

## Usage and examples

### Configuration

Set three environment variables to configure the client:

```
INSTAGRAM_CLIENT_ID=your_client_id
INSTAGRAM_CLIENT_SECRET=your_client_secret
INSTAGRAM_REDIRECT_URI=your_redirect_url
```

These variables can be obtained from the Facebook developer console.

### Using the client

When initializing the client, you can optionally pass in an auth token from Instagram, which will be used to make further requests. If you do not already have a token, you can use one of the methods provided to retrieve one.

```ruby
client = InstagramBasicDisplay::Client.new

# OR

client = InstagramBasicDisplay::Client.new(auth_token: token)
```

### Getting auth tokens

Authenticating with Instagram starts with an access code. This access code is retrieved by implementing Instagram's [authortization window](https://developers.facebook.com/docs/instagram-basic-display-api/overview#authorization-window), and is not covered by this gem.

Once you have an access code, you can exchange it for a short-lived authentication token.

```ruby
user = User.first
client = InstagramBasicDisplay::Client.new

short_token_request = client.short_lived_token(access_code: code)

if short_token_request.success?
  auth_token = token_request.payload.access_token
  expires_in = token_request.payload.expires_in
  user.update_instagram_token(token: token, expires_in: expires_in)
else
  render json: short_token_request.error, status: 400
end
```

You can exchange your short-lived token for a long-lived token.

```ruby
client = InstagramBasicDisplay::Client.new
user = User.first

long_token_request = client.long_lived_token(short_lived_token: user.instagram_token)

if long_token_request.success?
  auth_token = token_request.payload.access_token
  expires_in = token_request.payload.expires_in
  user.update_instagram_token(token: token, expires_in: expires_in)
else
  render json: long_token_request.error, status: 400
end
```

You can also pass an access code to `#long_lived_token`. It will be exchanged for a short-lived token, and then that will immediately be exchanged for a long-lived token.

```ruby
access_code = params[:access_code]
client = InstagramBasicDisplay::Client.new
user = User.first

long_token_request = client.long_lived_token(access_code: access_code)

if long_token_request.success?
  auth_token = token_request.payload.access_token
  expires_in = token_request.payload.expires_in
  user.update_instagram_token(token: token, expires_in: expires_in)
else
  render json: long_token_request.error, status: 400
end
```

You can refresh a long-lived token so that it remains valid for another period (at this stage, Instagram have set the validity period to 90 days).

```ruby
user = User.first
client = InstagramBasicDisplay::Client.new

refresh_request = client.refresh_long_lived_token(token: user.instagram_token)

if refresh_request.success?
  client.update_instagram_token(token: token_request.payload.access_token)
else
  render json: refresh_request.error, status: 400
end
```

To use an auth token when making requests, you can either pass it in when initializing the client,
or on-the-fly.

```ruby
auth_token = User.first.instagram_token

client = InstagramBasicDisplay::Client.new(auth_token: auth_token)

# OR

client = InstagramBasicDisplay::Client.new
client.configuration.auth_token = auth_token
```

### Getting profile information

You can retrieve a user's profile information (e.g. their username and Instagram id).

If no `user_id` is provided, the request will be made against the user associated with the client's auth token. For example:

```ruby
auth_token = User.first.instagram_token

client = InstagramBasicDisplay::Client.new(auth_token: auth_token)
response = client.profile

instagram_id = response.payload.id
instagram_username = response.payload.username
```

But you can also pass in a `user_id`, and request specific profile fields. Check the Instagram documentation to find out [which fields are supported](https://developers.facebook.com/docs/instagram-basic-display-api/reference/user#fields).

```ruby
user = User.first

client = InstagramBasicDisplay::Client.new(auth_token: user.instagram_token)
response = client.profile(user_id: user.instagram_id, fields: %i[username])

instagram_username = response.payload.username
```

### Getting media

You can query a user's media feed like this:

```ruby
user = User.first

client = InstagramBasicDisplay::Client.new(auth_token: user.instagram_token)
response = client.media_feed

media = response.payload.data
```

You can query for specific fields on the media, but by default you'll receive the `id` and `media_url` of each item. Refer to the Instagram documentation to [find out about other fields](https://developers.facebook.com/docs/instagram-basic-display-api/reference/media/).

```ruby
user = User.first

client = InstagramBasicDisplay::Client.new(auth_token: user.instagram_token)
response = client.media_feed(fields: %i[caption media_url])

media = response.payload.data
```

For pagination, the Instagram API provides previous/next links. Use those to retrieve the next page of results.

```ruby

user = User.first

client = InstagramBasicDisplay::Client.new(auth_token: user.instagram_token)

first_page = client.media_feed(fields: %i[caption media_url])

# you can ask the response whether there is a next/previous page
has_next_page_link = first_page.next_page?

# or ask for the url
next_page_link = first_page.next_page_link

second_page = client.media_feed(fields: %i[caption media_url], paginated_url: next_page_link)
```

You can pass some additional parameters to the media feed. They aren't yet well-documented by Instagram, but you can make some reasonable guesses at what will be accepted, based on the Facebook API. For example, to limit the number of results retrieved:

```ruby
user = User.first

client = InstagramBasicDisplay::Client.new(auth_token: user.instagram_token)
client.media_feed(limit: 10)
```

To retrieve a single piece of media, you'll need to know its id. As with the other requests, you can request whichever fields are supported by Instagram.

```ruby
user = User.first
client = InstagramBasicDisplay::Client.new(auth_token: user.instagram_token)

client.media_node(media_id: id, fields: %i[caption media_url id])
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/convertkit/instagram_basic_display. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.
