#!/usr/bin/python3
 
import pprint
import requests 
import RPi.GPIO as GPIO
import time
from enum import Enum

# LEDへ色を出力するときに使う天気一覧
class Condition(Enum):
     RAIN = 1
     CLOUDS = 2
     CLEAR = 3
     NONE = 4

# 天気をサーバーから取得する関数
def get_weather():
	# OpenWeatherに天気情報を問い合わせ
	response = requests.get(
		'http://api.openweathermap.org/data/2.5/forecast',
		params={'q':'Tokyo,JP','appid':'d4acb444201c0a3011c835374d6954ce'})

	# レスポンスがなければ天気が不明であるとして値を返す
	if response.status_code != requests.codes.ok:
		return Condition.NONE
	
	# 直近24時間(3時間ごと)の天気の情報を分析
	rain_count = 0
	clouds_count = 0
	for data in response.json()['list'][:8]:
		# pprint.pprint(data['dt_txt'])
		# pprint.pprint(data['weather'][0]['main'])
		condition = data['weather'][0]['main']
		if condition == 'Drizzle' \
			or condition == 'Rain' \
			or condition == 'Thunderstorm' \
			or condition == 'Snow':
			rain_count += 1
		if condition == 'Clouds':
			clouds_count += 1
	# 雨の予報が一定以上であれば現在の天気を雨とする
	if rain_count >= 1:
		return Condition.RAIN
	# 曇りの予報が一定以上であれば現在の天気を曇りとする
	if clouds_count >= 4:
		return Condition.CLOUDS
	# 雨でも曇りでもなければ晴れとする
	return Condition.CLEAR

# LEDの色をを天気によって切り替え
# 10秒ごとに最新の情報に更新
def led_loop():
	# Raspberry PIのGPIOピンを初期化
	GPIO.setmode(GPIO.BCM)
	GPIO.setup(14, GPIO.OUT) # 緑LED用
	GPIO.setup(15, GPIO.OUT) # 赤LED用
	GPIO.setup(18, GPIO.OUT) # 青LED用
	try:
		while True:
			# 現在の天気を取得
			condition = get_weather()
			# 天気の情報からLEDの出力を決定
			if condition == Condition.RAIN:
				GPIO.output(14, False)
				GPIO.output(15, False)
				GPIO.output(18, True)
			if condition == Condition.CLOUDS:
				GPIO.output(14, False)
				GPIO.output(15, True)
				GPIO.output(18, True)
			if condition == Condition.CLEAR:
				GPIO.output(14, True)
				GPIO.output(15, True)
				GPIO.output(18, True)
			if condition == Condition.NONE:
				GPIO.output(14, False)
				GPIO.output(15, False)
				GPIO.output(18, False)
			time.sleep(10)
	 
	except KeyboardInterrupt:
		pass
	 
	GPIO.cleanup()

def main():
	led_loop()

if __name__ == '__main__':
	main()
