require 'net/http'
require 'net/https'
require 'iconv'
require 'ftools'

$username='shenrui@cn.ibm.com'
$password='turp5n9v'

def update_file file_path,value_hash
   new_lines=Array.new
  
   yesterday = DateTime.now-1
   date_str=yesterday.month.to_s.rjust(2,"0")+"/"+yesterday.day.to_s.rjust(2,"0")+"/"+yesterday.year.to_s
   #~ puts date_str
   #~ puts date_str.gsub(/\//,'-')
   # backup old file
   bak_file_path=file_path+"."+date_str.gsub(/\//,'-')
   File.copy(file_path,bak_file_path)
   
   File.open(file_path,"r") do |file|
      while line=file.gets
          if line.index(date_str)
            parts=line.split(",")
            
            value_hash.each_key do |col_idx|
               col_val=value_hash[col_idx]
               parts[col_idx]=col_val.to_s
             end
             
            line=parts.join(",")
            line=line+"\n"
            puts "A line is updated as #{line}"
          end
          new_lines.push line
      end
    end
    
    File.open(file_path, 'w') {|f| 
        new_lines.each{ |line|
            f.write(line) 
        }
    }
    
  end
  
def get_bug_data queryUrl
	https=Net::HTTP.new('nsjazz.raleigh.ibm.com', 8002)
    https.use_ssl = true
    res = https.start do |http|
      
      #make the initial get to get the JSESSION cookie
      get = Net::HTTP::Get.new("https://nsjazz.raleigh.ibm.com:8002/jazz/web")
      response = http.request(get)
      
      #authorize
      post = Net::HTTP::Post.new('https://nsjazz.raleigh.ibm.com:8002/jazz/j_security_check')
      post.set_form_data({'j_username'=>$username, 'j_password'=>$password})
      #~ post['Cookie'] = cookie
      response=http.request(post)
            
      cookie=response.response['set-cookie'].split(';')[0]
      
      get = Net::HTTP::Get.new(response['location'])
      get['Cookie']=cookie
      response=http.request(get)
      
      get = Net::HTTP::Get.new(queryUrl)
      get['Cookie']=cookie
      response=http.request(get)
	  csv_data=Iconv.iconv("UTF-8", "UTF-16", response.body) 
      return csv_data
     end
end
   
def get_bug_count queryUrl
    bug_data=get_bug_data(queryUrl)
    line_count=0
    bug_data.to_s.each {|line|
        line_count+=1
    }
    return line_count-1
end  