require "date"
require "flickraw"

FlickRaw.api_key = "<your_api_key>"
FlickRaw.shared_secret = "<your_shared_secret>"

# Set earliest upload date to the a little before the earliest date 
# you've uploaded a picture to Flickr (e.g. "2004-06-01 00:00:00")
EarliestUploadDate = DateTime.parse("<your_earliest_date>")
LatestUploadDate = DateTime.now

# Authenticate

frob = flickr.auth.getFrob
auth_url = FlickRaw.auth_url :frob => frob, :perms => 'write'

puts "Open this url in your process to complete the authication process : #{auth_url}"
puts "Press Enter when you are finished."
STDIN.getc

begin
	auth = flickr.auth.getToken :frob => frob
	login = flickr.test.login
	puts "You are now authenticated as #{login.username} with token #{auth.token}"
rescue FlickRaw::FailedResponse => e
	puts "Authentication failed : #{e.msg}"
end

# Go through every photo in the photostream and delete the photo's tags. Inefficient,
# I know, but it's the only way I saw in Flickr's API to do this.

max_upload_date = EarliestUploadDate
format = "%Y-%m-%d %H:%M:%S"

begin
	min_upload_date = max_upload_date
	max_upload_date = max_upload_date >> 1
	puts "Looking for photos uploaded from #{min_upload_date.strftime(format)} through #{max_upload_date.strftime(format)}"
	
	page = 1
	while true
		puts "Getting page #{page} of results"
		photos = flickr.photos.search :user_id => "me", 
			:min_upload_date => min_upload_date.strftime(format), 
			:max_upload_date => max_upload_date.strftime(format),
			:per_page => 25,
			:page => page
		
		photos.each do |photo|
			puts "Getting info for photo '#{photo.title}'"
			info = flickr.photos.getInfo :photo_id => photo.id
			
			info.tags.each do |tag|
				puts "... Removing tag '#{tag.raw}' from photo '#{photo.title}"
				flickr.photos.removeTag :tag_id => tag.id
			end
		end
		
		break if page == photos.pages
		page = page + 1
	end	
end while max_upload_date <= LatestUploadDate