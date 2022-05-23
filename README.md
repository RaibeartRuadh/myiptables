# Port Knocking - 
это сетевой защитный механизм, действие которого основано на следующем принципе: сетевой порт является по-умолчанию закрытым, но до тех пор, пока на него не поступит заранее определённая последовательность пакетов данных, которая «заставит» порт открыться. Например, вы можете сделать «невидимым» для внешнего мира порт SSH, и открытым только для тех, кто знает нужную последовательность.
Данный репозиторий симулируют данный механизм, используя виртуальные машины.

# Для проверки работы вам потребуется установить:
- Ansible 2.9.6
- Oracle VirtualBox 6.0
- Vagrant Vagrant 2.2.19

Если по команде vagrant up из основной директории проекта выдает ошибку образа, требуется скачать и установить образ, аналогичный Centos 7 -  https://app.vagrantup.com/centos/boxes/7
Также трубется заменить название образа, которое вы указали при загрузке (команда vagrant box add --name ИМЯ_ОБРАЗА URL or Address to Image) в файле Vagrantfile проекта.

      Vagrant.configure("2") do |config|
         config.vm.box = "ИМЯ_ОБРАЗА"

------------------------------------------------------------

# Сценарии iptables
1) реализовать knocking port
- centralRouter может попасть на ssh inetrRouter через knock скрипт
пример в материалах
2) добавить inetRouter2, который виден(маршрутизируется (host-only тип сети для виртуалки)) с хоста или форвардится порт через локалхост
3) запустить nginx на centralServer
4) пробросить 80й порт на inetRouter2 8080
5) дефолт в инет оставить через inetRouter

# Решение

Общий костяк был взят из задания "Cетевая лаборатория", к которому был добавлен InetRouter2
Доступ по ssh на сервер 192.168.255.1 закрыт правилами iptables, которые требуют определенной последовательности подключений к заданным закрытым портам. В том случае, если последовательность будет соблюдена, фаерволл откроет доступ к 22 порту на ограниченное время. 
Наши правила предполагают, что это будут порты: 8881 7777 и 9991
После правильного "простукивания", 22й порт будет открыт на 30 секунд.

              *filter
              :INPUT DROP [0:0]
              :FORWARD ACCEPT [0:0]
              :OUTPUT ACCEPT [0:0]
              :TRAFFIC - [0:0]
              :SSH-INPUT - [0:0]
              :SSH-INPUTTWO - [0:0]
              # 
              -A INPUT -j TRAFFIC
              -A TRAFFIC -p icmp --icmp-type any -j ACCEPT
              -A TRAFFIC -m state --state ESTABLISHED,RELATED -j ACCEPT
              -A TRAFFIC -m state --state NEW -m tcp -p tcp --dport 22 -m recent --rcheck --seconds 30 --name SSH2 -j ACCEPT
              -A TRAFFIC -m state --state NEW -m tcp -p tcp -m recent --name SSH2 --remove -j DROP
              -A TRAFFIC -m state --state NEW -m tcp -p tcp --dport 9991 -m recent --rcheck --name SSH1 -j SSH-INPUTTWO
              -A TRAFFIC -m state --state NEW -m tcp -p tcp -m recent --name SSH1 --remove -j DROP
              -A TRAFFIC -m state --state NEW -m tcp -p tcp --dport 7777 -m recent --rcheck --name SSH0 -j SSH-INPUT
              -A TRAFFIC -m state --state NEW -m tcp -p tcp -m recent --name SSH0 --remove -j DROP
              -A TRAFFIC -m state --state NEW -m tcp -p tcp --dport 8881 -m recent --name SSH0 --set -j DROP
              -A SSH-INPUT -m recent --name SSH1 --set -j DROP
              -A SSH-INPUTTWO -m recent --name SSH2 --set -j DROP 
              -A TRAFFIC -j DROP
              COMMIT

Проверяем работу.
- поднимаем стенд:

              $ vagrant up
 
 (обратить внимание, что применились наши правила для iptables и сервис sshd был рестартован!
 ![alt text](https://github.com/RaibeartRuadh/myiptables/blob/main/snap1.png?raw=true "Обратить внимание, что правила iptables применились и sshd рестартовал.")
  
 - подключаемся к centralRouter
 
              $ vagrant ssh centralRouter
 
 - повышаем полномочия
 
              $ sudo -i
 
 - пробуем подключиться к inetRouter по ssh
 
              $ ssh vagrant@192.168.255.1
 
 Если наши правила применились, до доступ получить не получается. При этом сервер пингуется.
 
 - Пробуем нашу "секретную" последовательность портов. Для этого можно использовать пакет nmap или hping3. Я приведу примеры для обоих вариантов
 
 - Вариант с nmap
 
               $ nmap -Pn --host-timeout 201 --max-retries 0  -p 8881 host 192.168.255.1; nmap -Pn --host-timeout 201 --max-retries 0  -p 7777 host 192.168.255.1; nmap -Pn --host-timeout 201 --max-retries 0  -p 9991 host 192.168.255.1

- Вариант с hping3
 
               $ hping3 -S 192.168.255.1 -p 8881 -c 1; hping3 -S 192.168.255.1 -p 7777 -c 1; hping3 -S 192.168.255.1 -p 9991 -c 1

При необходимости можно организовать скрипт:

            !#/bin/bash/
            nmap -Pn --host-timeout 201 --max-retries 0  -p 8881 host 192.168.255.1
            nmap -Pn --host-timeout 201 --max-retries 0  -p 7777 host 192.168.255.1
            nmap -Pn --host-timeout 201 --max-retries 0  -p 9991 host 192.168.255.1

- вариант с hping3

            !#/bin/bash/
            hping3 -S 192.168.255.1 -p 8881 -c 1
            hping3 -S 192.168.255.1 -p 7777 -c 1
            hping3 -S 192.168.255.1 -p 9991 -c 1

Скрит уже находится на centralRouter в домашней директории, его нужно только вызвать 

              $ chmod +x test.sh && ./test.sh

- пробуем снова подключиться к 192.168.255.1 через ssh


              $ ssh vagrant@192.168.255.1

- Ура! получается. От волнения дважды ошибаюсь с вводом штатного пароля vagrant, но запаса в 30 секунд хватат. Доступ на сервер получен!

 ![alt text](https://github.com/RaibeartRuadh/myiptables/blob/main/snap2.png?raw=true "")

На centralServer у нас установлен nginx, на inetRouter2 прописаны правила

        iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 8080 -j DNAT --to-destination 192.168.0.2:80
        iptables -t nat -A POSTROUTING ! -s 127.0.0.1 -j MASQUERADE

Проверяем браузер на localhost:8080

Видим дефолтную картинку в браузере

![alt text](https://github.com/RaibeartRuadh/myiptables/blob/main/snap3.png?raw=true "")


Материалы:
1. https://habr.com/ru/post/470001/
2. https://otus.ru/nest/post/267/
3. https://itsecforu.ru/2018/02/06/hping3-%D1%81%D0%B5%D1%82%D0%B5%D0%B2%D0%BE%D0%B9-%D1%81%D0%BA%D0%B0%D0%BD%D0%B8%D1%80%D1%83%D1%8E%D1%89%D0%B8%D0%B9-%D0%B8%D0%BD%D1%81%D1%82%D1%80%D1%83%D0%BC%D0%B5%D0%BD%D1%82-%D0%B3%D0%B5%D0%BD/
4. https://wiki.archlinux.org/index.php/Port_knocking
