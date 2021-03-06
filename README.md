# Chair
[![Build Status](http://img.shields.io/travis/toroidal-code/chair/master.svg?style=flat)](https://travis-ci.org/toroidal-code/chair)
[![Coverage](https://img.shields.io/codeclimate/coverage/github/toroidal-code/chair.svg?style=flat)](https://codeclimate.com/github/toroidal-code/chair)
[![Gem Version](http://img.shields.io/gem/v/chair.svg?style=flat)](https://rubygems.org/gems/chair)

> Me: What's the first thing you think of when I say 'Table'?  
> J: 'Chair'.

Chair is a simple table implementation for Ruby, with an associated Row class.

## Installation

Add this line to your application's Gemfile:

    gem 'chair'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install chair

## Usage

```irb
>> require 'chair'  
=> true
>> t = Chair.new :title
=> #<Chair:0x0000000162ee08>
>> t.set_primary_key! :title
=> :title
>> t.insert! title: 'Looking for Alaska'
=> #<Chair::Row:0x007feb28035be0>
>> t.find_by_title('Looking for Alaska').to_a
>> ["Looking for Alaska"]
>> t.add_column! :author
=> true
>> t.insert! title: 'An Abundance of Katherines', author: 'John Green'
=> #<Chair::Row>
>> t.add_index! :author
=> true
>> t.find_by_author('John Green').to_a
=> ["An Abundance of Katherines", "John Green"]
>> t.find_by_title('Looking for Alaska')[:author] = 'John Green'
=> 'John Green'
>> r = t.where_author_is 'John Green'
=> [#<Chair::Row>, #<Chair::Row>]
>> r.map {|r| r.to_a}
=> [["An Abundance of Katherines", "John Green"], ["Looking for Alaska", "John Green"]]
```

## Contributing

1. Fork it ( https://github.com/toroidal-code/chair/fork )
2. Create your feature branch (`git checkout -b features/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin features/my-new-feature`)
5. Create a new Pull Request
