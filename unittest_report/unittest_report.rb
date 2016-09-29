require 'net/http'
require 'net/https'
require 'hpricot'
require 'mailfactory'
require 'net/smtp'
require 'yaml'

@@gsa_user='shenrui'
@@gsa_pwd='1234qwer'

BUILD_FILE='last_build.txt'
build_orig=""
last_build=""
index_page='https://rtpmsa.raleigh.ibm.com/msa/.projects/p1/lotusmashups/public/current/builds/daily/'

if File.exists? BUILD_FILE
  last_build=open(BUILD_FILE) {|f| YAML.load(f) }
end

https=Net::HTTP.new('rtpmsa.raleigh.ibm.com', 443)
https.use_ssl = true
https.start do |http|
      get = Net::HTTP::Get.new(index_page)
      get.basic_auth 'shenrui', '1234qwer'
      #~ get = Net::HTTP::Get.new('/jazz/web')
      resp = http.request(get)
      html=resp.body
      doc=Hpricot(html)
      hrefs=doc.search("//a")
      build_orig=hrefs[hrefs.length-1].inner_text  
      p "Build#: #{build_orig}"
end
    
if build_orig==last_build
  p "Ignore - #{build_orig} unit test report has ever been sent."
  exit 0
end

class Report
  def initialize report_type,build,report_name
    @report_type=report_type
    @build=build
    @report_name=report_name
  end
  
  def get_report
    build_temp=@build.gsub(/\s/,'%20')
    link_summary="https://rtpmsa.raleigh.ibm.com/msa/.projects/p1/lotusmashups/public/current/builds/daily/#{build_temp}/reports/#{@report_type}/html/overview-summary.html"
    link_index="https://rtpmsa.raleigh.ibm.com/msa/.projects/p1/lotusmashups/public/current/builds/daily/#{build_temp}/reports/#{@report_type}/html/index.html"
    link_alltests="https://rtpmsa.raleigh.ibm.com/msa/.projects/p1/lotusmashups/public/current/builds/daily/#{build_temp}/reports/#{@report_type}/html/all-tests.html"
    link_fails="https://rtpmsa.raleigh.ibm.com/msa/.projects/p1/lotusmashups/public/current/builds/daily/#{build_temp}/reports/#{@report_type}/html/alltests-fails.html"
    link_errors="https://rtpmsa.raleigh.ibm.com/msa/.projects/p1/lotusmashups/public/current/builds/daily/#{build_temp}/reports/#{@report_type}/html/alltests-errors.html"

    https=Net::HTTP.new('rtpmsa.raleigh.ibm.com', 443)
    https.use_ssl = true
    https.start do |http|
              get2 = Net::HTTP::Get.new(link_summary)
              get2.basic_auth @@gsa_user, @@gsa_pwd
              resp = http.request(get2)
              status=resp.code
              if(status=="200")
                  html=resp.body
                  #~ p html
                  doc=Hpricot(html)
                  table=doc.search("//table[@class=details]")[0]
                  hrefs=table.search("//a")
                  tests=hrefs[0].inner_text
                  failures=hrefs[1].inner_text
                  errors=hrefs[2].inner_text
                  succ_rate=table.search("//td")[3].inner_text
                  
                  section_title="Summary for #{@report_name} report"
                  
                  html_content=""
                  html_content<<"<div style='margin-top: 2em;font-family:normal 68% verdana,arial,helvetica'><b>#{section_title}</b></div>"
                  html_content<<"<table width='600px' style='border: 1px solid gray'><thead><tr style='background-color:#a6caf0'><th>Tests</th><th>Failures</th><th>Errors</th><th>Success rate</th></tr></thead><tbody><tr>"
                  html_content<<"<td style='background-color:#eeeee0;text-align:center'><a href='#{link_alltests}' target='_blank'>#{tests}</a></td>"
                  html_content<<"<td style='background-color:#eeeee0;text-align:center'><a href='#{link_fails}' target='_blank'>#{failures}</a></td>"
                  html_content<<"<td style='background-color:#eeeee0;text-align:center'><a href='#{link_errors}' target='_blank'>#{errors}</a></td>"
                  html_content<<"<td style='background-color:#eeeee0;text-align:center'>#{succ_rate}</td>"
                  html_content<<"</tr></tbody></table>"
                  html_content<<"<br><a href='#{link_index}' target='_blank' style='margin-top: 2em;font-family:normal 68% verdana,arial,helvetica'>Unit Test Results Index Page</a><br>"
              
              elsif status=="404"
                  html_content="No report is found."
                    
              end
              return html_content     
  end
end
end

# construct email content
junit_report=Report.new('junit',build_orig,'JUnit').get_report
dojotest_report=Report.new('dojotest',build_orig,'DojoTest').get_report

html_content=""
html_content<<junit_report<<'<br>'<<dojotest_report

to_emails=Array.new
# load reciver emails
File.open('distribution_list.txt','r'){ |file|
  while line=file.gets
     line=line.chop
     to_emails<<line unless line.empty?
  end
}
p to_emails

File.open('email_content.html','w'){|f|
    f.write(html_content)
}

mail=MailFactory.new 
mail.encoding="UTF-8" 

from_email='comitium@us.ibm.com'
#~ to_emails=['shenrui@cn.ibm.com','scottchapman@us.ibm.com']
#~ to_emails=['shenrui@cn.ibm.com']

mail.to=[to_emails].join(',')
mail.subject="Unit Test Results Summary (build# #{build_orig})"
mail.html=html_content
Net::SMTP.start('9.181.32.74') do |smtp|
  smtp.send_message(mail.to_s,from_email,to_emails)
  p "An email is sent."
end

open(BUILD_FILE, 'w') {|f| YAML.dump(build_orig, f)}
p "The build# is saved."

   
