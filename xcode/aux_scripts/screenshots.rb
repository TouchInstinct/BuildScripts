
require 'net/http'
require 'rest-client'
require 'json'
require 'fileutils'
require 'docopt'

def screenshots(token, file, folder)
  
  baseUrl = 'https://api.figma.com/v1/'
  filesUrl = 'files/'
  imageUrl = 'images/'
  figmaToken = token;
  figmaFile = file;
  imagesFolder = folder;
  imagesFormat = "png"

  ####################################################
  puts '🌿 Start.'
  ####################################################

  ####################################################
  puts '🌿 Get all nodes for file...'
  ####################################################

  # 2. Get all nodes for file with screenshots
  response = RestClient::Request.new(
     :method => :get,
     :url => baseUrl + filesUrl + figmaFile,
     :headers => {
        'X-FIGMA-TOKEN': figmaToken
     },
     :verify_ssl => false
  ).execute
  results = JSON.parse(response.to_str)

  ####################################################
  puts '🌿 Get url for image...'
  ####################################################

  # 3. Create dictionary with url screenshots
  screenshotPage = String.new
  pages = results['document']['children']
  for tempPage in pages
      if tempPage['name'] == 'Screenshots' then
          screenshotPage = tempPage
          break
      end
  end

  screenshotIds = String.new
  screenshotFrames = Hash.new
  groups = screenshotPage['children']
  for tempGroup in groups
      
      if tempGroup['type'] == 'GROUP' then
          groupName = tempGroup['name']
          nodes = tempGroup['children']
          
          for tempNode in nodes
              if tempNode['type'] == 'FRAME' then
                  screenshotFrames[tempNode['id']] = '/' + groupName + '/' + tempNode['name']
                  screenshotIds += tempNode['id'] + ','
              end
          end
      end
  end

  # 4. Get url for images
  response = RestClient::Request.new(
     :method => :get,
     :url => baseUrl+imageUrl+figmaFile,
     :headers => {
        'X-FIGMA-TOKEN': figmaToken,
        :params => {:ids => screenshotIds[0..-2], :scale => 3, :format => imagesFormat},
     },
     :verify_ssl => false
  ).execute
  results = JSON.parse(response.to_str)

  ####################################################
  puts '🌿 Download images...'
  ####################################################

  # 5. Download images in folders
  imagesUrl = results['images']
  imagesUrl.each do |key, value|
      data = RestClient.get(value).body
      folder = (imagesFolder + screenshotFrames[key]).chop
      FileUtils.mkdir_p folder
      File.write(imagesFolder + screenshotFrames[key] + '.' + imagesFormat, data, mode: 'wb')
  end

  ####################################################
  puts '🌿 Finish. Hooray!'
  ####################################################

end
