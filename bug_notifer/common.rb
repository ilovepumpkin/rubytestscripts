require 'net/http'
require 'net/https'
require 'iconv'
require 'ftools'
require 'yaml'
require 'singleton'
require 'ParseDate'
require 'mailfactory'
require 'net/smtp'
require 'date'

$username='shenrui@cn.ibm.com'
$password='turp5n9v'

RECEIVER_OWNER='owner'
RECEIVER_CREATOR='creator'

LONG_AGE=7

class EmailUtil
  def EmailUtil.send subject,content,from_email,to_emails
    mail=MailFactory.new 
    mail.encoding="UTF-8" 
    
    mail.to=[to_emails].join(',')
    mail.subject=subject
    mail.html=content
    Net::SMTP.start('9.181.32.74') do |smtp|
      smtp.send_message(mail.to_s,from_email,to_emails)
    end
  end
end

class BugNotifier
  attr_accessor :debug
  
  def initialize query_url,receiver_type,subject,cc_emails
    @email_fetcher=EmailFetcher.instance
    @query_url=query_url
    @receiver_type=receiver_type
    @to_emails=Array.new
    @bug_list=BugList.new
    @cc_emails=cc_emails
    @subject=subject
  end
  
  def notify 
      csv_data=get_bug_data(@query_url)[0]
	  
      line_index=0
      
      duedate_index=-1;
      summary_index=-1;
      owner_index=-1;
      creator_index=-1;
      severity_index=-1;
      priority_index=-1;
      createdate_index=-1;
      status_index=-1;
      id_index=-1;

      array_data=csv_data.split("\n")
      array_data.each{|line|
             line_index+=1
             temp=line.split("\t")
             temp.collect!{|elem|
                    len=elem.length-2
                    elem=elem.slice(1..len)
            }
             if line_index==1
                 id_index=temp.index("Id")
                 duedate_index=temp.index("Due Date")
                 summary_index=temp.index("Summary")
                 owner_index=temp.index("Owned By")
                 severity_index=temp.index("Severity")
                 createdate_index=temp.index("Creation Date")
                 creator_index=temp.index("Created By")
                 priority_index=temp.index("Priority")
                 status_index=temp.index("Status")
             else
                    bug=Bug.new
                    bug.id=temp[id_index] if id_index!=nil
                    bug.due_date=temp[duedate_index] if duedate_index!=nil
                    bug.summary=temp[summary_index] if summary_index!=nil
                    bug.owned_by=temp[owner_index] if owner_index!=nil
                    bug.severity=temp[severity_index] if severity_index!=nil
                    bug.create_date=temp[createdate_index] if createdate_index!=nil
                    bug.creator=temp[creator_index] if creator_index!=nil
                    bug.priority=temp[priority_index] if priority_index!=nil
                    bug.status=temp[status_index] if status_index!=nil
               
                    accept=yield bug
                    if accept
                      @bug_list<< bug
                      if @receiver_type==RECEIVER_OWNER
                          to_email=@email_fetcher.get_email bug.owned_by
                      elsif @receiver_type==RECEIVER_CREATOR
                          to_email=@email_fetcher.get_email bug.creator
                      end
                      
                      if @to_emails.index(to_email)==nil
                          @to_emails<<to_email
                      end
                    end  
             end
      }
      
      @to_emails.concat @cc_emails
      p @subject
      p @to_emails
      html_content=@bug_list.to_table_html @receiver_type
      
      @email_fetcher.save
      
      if debug==true
          @to_emails=['shenrui@cn.ibm.com']
      end        
      
      File.open('email_content.html','w'){|f|
          f.write(html_content)
      }
      
      if @bug_list.length>0
          EmailUtil.send @subject,html_content,'shenrui@cn.ibm.com',@to_emails
      end
  end
end

class Bug
  attr_accessor :id,:summary,:severity,:priority,:owned_by,:creator,:create_date,:due_date,:status
  def age
      date1= ParseDate::parsedate(create_date)
      d_create_date= Date.new(date1[0],date1[1],date1[2])

      now=DateTime.now

      return (now-d_create_date).to_i
    end
    
  def create_date_html
    return "&nbsp;" if create_date==nil
    date1= ParseDate::parsedate(create_date)
    d_create_date= Date.new(date1[0],date1[1],date1[2])
    return "#{date1[1]}/#{date1[2]}/#{date1[0]}"
  end  
  
  def due_date_html
    if due_date==""
      return "&nbsp;"
    else  
      date1= ParseDate::parsedate(due_date)
      d_create_date= Date.new(date1[0],date1[1],date1[2])
      return "#{date1[1]}/#{date1[2]}/#{date1[0]}"
    end
  end  
  
  def to_tr_html receiver_type
      bg_color="white"
      if receiver_type==RECEIVER_OWNER
          bg_color="yellow" if self.age>=LONG_AGE
      end
      tr_html="<tr style='background-color:#{bg_color}'><td><a href='https://nsjazz.raleigh.ibm.com:8002/jazz/web/projects/Mashup%20Center#action=com.ibm.team.workitem.viewWorkItem&id=#{id}' target='_blank'>#{id}</a></td><td>#{summary}</td><td>#{status}</td><td>#{severity}</td><td>#{priority}</td><td>#{owned_by}</td><td>#{creator}</td><td>#{create_date_html}</td><td>#{age}</td><td>#{due_date_html}</td></tr>"
  end
end

class BugList<Array
     
  def to_table_html receiver_type
     table="<b>Total bug count:</b>&nbsp;#{self.length}<br>"
     if receiver_type==RECEIVER_OWNER
        table<<"<font color='blue'>The bugs with long age(>=#{LONG_AGE}) are marked in yellow background.</font><br>"
     end
     table<<"<table border=1 width='95%' style='font-size:10pt'><thead><tr style='background-color:lightgrey'><th width='50px'>Id</th><th>Summary</th><th width='100px'>Status</th><th width='100px'>Severity</th><th width='100px'>Priority</th><th>Owned_By</th><th>Created By</th><th>Creation Date</th><th width='40px'>Age</th><th width='100px'>Due Date</th></tr></thead><tbody>"
     self.each{|bug|
          table<<bug.to_tr_html(receiver_type)
     }
     table<<"</tbody></table>"
   end
   
   public :to_table_html
end

class EmailFetcher
	include Singleton
  
  EMAIL_FILE='user_emails.yml'
  
  def get_email_fromjazz user_name
    #~ p "...get user email from jazz server..."
    encoded_user_name=user_name.gsub(/ /,'%20')
    user_query="https://nsjazz.raleigh.ibm.com:8002/jazz/service/com.ibm.team.process.internal.common.service.IProcessRestService/contributors?sortBy=name&searchTerm=#{encoded_user_name}&searchField=name&pageSize=250&hideAdminGuest=false&hideUnassigned=true&hideArchivedUsers=true&pageNum=0"
    #~ p user_query
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
      
      get = Net::HTTP::Get.new(user_query)
      get['Cookie']=cookie
      response=http.request(get)
    
      user_data=response.body
    
      email=user_data.scan(/<emailAddress>(.*)<\/emailAddress>/)[0][0]
      #~ p email
      
      return email
    end
    
  end   
  
  def save
      open(EMAIL_FILE, 'w') {|f| YAML.dump(@user_emails, f)}
  end
    
  def initialize
         if File.exists? EMAIL_FILE
            @user_emails=open(EMAIL_FILE) {|f| YAML.load(f) }
         else
            @user_emails=Hash.new
         end
  end
    
  def get_email user_name
      email=@user_emails[user_name]
      if(email==nil)
          email=get_email_fromjazz user_name
          @user_emails[user_name]=email
      else
         #~ p "found email for #{user_name}"
      end
      return email  
  end 
    
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