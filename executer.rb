require 'uri'
require 'net/ssh'

class Handler
  def initialize()
    @devices = {
      wtf: "ios",
      "ZX1D63SX4D": "android"
    }
    @ios_device_ip ={
      wtf: "10.100.101.211"
    }
  end

  def start_browser(url,device_id)
    result, uri = urlCheck(url)
    return false, uri unless result
    device = @devices[device_id.to_sym]
    if device == "android"
      start_browser_android(uri.to_s,device_id)
    else
      start_browser_iOS(uri.to_s,@ios_device_ip[device_id.to_sym])
    end
  end

  def stop_browser(device_id)
    device = @devices[device_id.to_sym]
    if device == "android"
      stop_browser_android(device_id)
    else
      stop_browser_iOS(@ios_device_ip[device_id.to_sym])
    end
  end

  private

  def start_browser_android(url,device_id)
    wake_up_device
    out = "adb -s #{device_id} shell am start -a android.intent.action.VIEW -d \"#{url}\" com.android.chrome"
    puts "#{out}"
    out = `#{out} 2>&1`
    return false, "Device is offline" if out.include? "error:"
    return true, "URL Opened"
  end

  def stop_browser_android(device_id)
    wake_up_device
    out = "adb -s #{device_id} shell am force-stop com.android.chrome"
    out = `#{out} 2>&1`
    return false, "Device is offline" if out.include? "error:"
    return true, "Browser closed"
  end

  def start_browser_iOS(url,device_ip)
    ssh_session = connect_to_ios_device(device_ip)
    return false, "Device is offline" unless ssh_session
    ssh_session.exec! "uiopen #{url}"
    return true, "Url Opened"
  end

  def stop_browser_iOS(device_ip)
    ssh_session = connect_to_ios_device(device_ip)
    return false, "Device is offline" unless ssh_session
    puts ssh_session.exec! "killall MobileSafari"
  end

  def wake_up_device
    if(`adb shell dumpsys power | grep 'Display Power: state=OFF'`.include?'OFF')
      `adb shell input keyevent 82`
    end
  end

  def urlCheck(url)
    uri = URI(url)
    if !uri.scheme
      uri.scheme = "http"
    elsif !(%w{http https}.include?(uri.scheme))
      return false, "Check your URL please"
    end
    return true, uri
  end

  def connect_to_ios_device(device_ip)
    host = device_ip
    user = 'root'  # username
    pass = "alpine"  # password
    s=false
    begin
      timeout 2 do
        s = Net::SSH.start(host, user, :password => pass)
      end
    rescue Exception => ex
      puts ex
      return false if ex.to_s.include? "expired"
    end
    return s
  end

end
