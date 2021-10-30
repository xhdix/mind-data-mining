#!/usr/bin/env python
# coding: utf-8
# source: https://gist.github.com/hellais/de19a104681402e9b9b63df73dd0f5d7

# In[4]:


import csv
import json
import sys
from datetime import datetime, timezone
from time import sleep

import pandas as pd
import requests

# In[5]:


if len(sys.argv) < 2:
    print("run: python ./IODAIranDATA.py sinceTimestamp untilTimestamp")
    exit()

sincets = int(sys.argv[1])
untilts = int(sys.argv[2])
sincestr = datetime.utcfromtimestamp(sincets).strftime('%Y-%m-%dT%H-%M-%SZ')
untilstr = datetime.utcfromtimestamp(untilts).strftime('%Y-%m-%dT%H-%M-%SZ')


def count_expression(asn):
    return {
        "type": "function",
        "func": "removeEmpty",
        "args": [
            {
                "type": "function",
                "func": "group",
                "args": [
                    {
                        "type": "function",
                        "func": "alias",
                        "args": [
                            {
                                "type": "path",
                                "path": "bgp.prefix-visibility.asn.{}.v4.visibility_threshold.min_50%_ff_peer_asns.visible_slash24_cnt".format(asn)
                            },
                            {
                                "type": "constant",
                                "value": "BGP (# Visible \/24s)"
                            }
                        ]
                    },
                    {
                        "type": "function",
                        "func": "alias",
                        "args": [
                            {
                                "type": "path",
                                "path": "darknet.ucsd-nt.non-erratic.routing.asn.{}.uniq_src_ip".format(asn)
                            },
                            {
                                "type": "constant",
                                "value": "Darknet (# Unique Source IPs)"
                            }
                        ]
                    },
                    {
                        "type": "function",
                        "func": "alias",
                        "args": [
                            {
                                "type": "function",
                                "func": "sumSeries",
                                "args": [
                                    {
                                        "type": "function",
                                        "func": "keepLastValue",
                                        "args": [
                                            {
                                                "type": "path",
                                                "path": "active.ping-slash24.asn.{}.probers.team-1.caida-sdsc.*.up_slash24_cnt".format(asn)
                                            },
                                            {
                                                "type": "constant",
                                                "value": 1
                                            }
                                        ]
                                    }
                                ]
                            },
                            {
                                "type": "constant",
                                "value": "Active Probing (# \/24s Up)"
                            }
                        ]
                    }
                ]
            }
        ]
    }


def get_chart(asn='12880', since='1578960000', until='1579046400', expression=count_expression):
    base_url = 'https://ioda.caida.org/data/ts/json'
    params = {
        'from': since,
        'until': until,
        'expression': json.dumps(expression(asn))
    }

    r = requests.post(base_url, data=params)
    j = r.json()
    col_name_map = {
        'removeEmpty(BGP (# Visible \\/24s))': 'bgp',
        'removeEmpty(Darknet (# Unique Source IPs))': 'darknet',
        'removeEmpty(Active Probing (# \\/24s Up))': 'active_probing'
    }
    cols = {}
    for key in j['data']['series'].keys():
        col_name = col_name_map[key]
        cols[col_name] = j['data']['series'][key]
    return cols


# In[6]:


asn_list = [
    ['44244', 'IranCell', 'Filternet'],
    ['197207', 'MCCI', 'Filternet'],
    ['58224', 'IranTelecomCo', 'Filternet'],
    ['12880', 'ITC', 'Gateway'],
    ['49666', 'TIC', 'Gateway'],
    ['48159', 'TIC', 'Gateway'],
    ['6736', 'IRANET-IPM', 'Gateway'],
    ['29049', 'DeltaTelecom', 'Transit'],
    ['6453', 'TATA', 'Transit'],
    ['5511', 'Orange', 'Transit'],
    ['6939', 'HurricaneElectric', 'Transit'],
    ['6762', 'TelecomItaliaSpa', 'Transit'],
    ['1299', 'TeliaCoAB', 'Transit'],
    ['39533', 'AsymptoNetKft', 'Transit'],
    ['200612', 'GulfBridgeInt', 'Transit'],
    ['49832', 'QBIC-fka-Rikeza', 'Transit'],
    ['1239', 'Sprint', 'Transit'],
    ['31549', 'Shatel', 'Filternet'],
    ['16322', 'ParsOnline', 'Filternet'],
    ['41689', 'Asiatech', 'Filternet'],
    ['43754', 'Asiatech', 'Filternet'],
    ['57218', 'Rightel', 'Filternet'],
    ['62140', 'Rightel', 'Filternet'],
    ['209459', 'AbrArvan', 'Filternet'],
    ['202468', 'AbrArvan', 'Filternet'],
    ['50810', 'Mobinnet', 'Filternet'],
    ['39501', 'NGSAS-aka-Sabanet', 'Filternet'],
    ['48147', 'AminIDC', 'Filternet'],
    ['49100', 'IR-THR-PTE', 'Filternet'],
    ['47262', 'Hamara', 'Filternet'],
    ['56402', 'Dadehgostar', 'Filternet'],
    ['62442', 'DadeSamaneFanava', 'Filternet'],
    ['39164', 'DadeSamaneFanava', 'Filternet'],
    ['61036', 'FanavaGroup', 'Filternet'],
    ['60637', 'FanavaGroup', 'Filternet'],
    ['41881', 'FanavaGroup', 'Filternet'],
    ['42337', 'Respina', 'Filternet'],
    ['25124', 'Datak', 'Filternet']
]


# In[ ]:


with open(sincestr + '_' + untilstr + '_ioda-iran.csv', 'w+') as out_file:
    writer = csv.DictWriter(out_file, fieldnames=[
                            'datasource', 'value', 'as_name', 'datetime', 'timestamp', 'net_type'])
    writer.writerow({
        'value': 'Value',
        'as_name': 'Network',
        'datasource': 'Data source',
        'datetime': 'Date & Time',
        'timestamp': 'Timestamp',
        'net_type': 'Network type'
    })

    for asnum, asn_name, net_type in asn_list:
        # since = int(datetime(2021, 9, 22, 23, 59, tzinfo=timezone.utc).timestamp())
        # until = int(datetime(2021, 9, 29, 21, 29, tzinfo=timezone.utc).timestamp())
        since = sincets
        until = untilts
        print('Downloading {}'.format(asnum))
        try:
            chart = get_chart(asn=asnum, since='{}'.format(
                since), until='{}'.format(until))
        except Exception as exc:
            if format(exc) == "'NoneType' object has no attribute 'keys'":
                print('there is no data for ' + asnum)
            else:
                print('Exception {}'.format(exc))
            continue

        step_range = int((until - since)/300)
        for datasource in ['bgp', 'darknet', 'active_probing']:
            if datasource not in chart:
                print('{} missing!'.format(datasource))
                continue
            step = chart[datasource]['step']
            timestamp = since
            idx = 0
            while timestamp < until:
                writer.writerow({
                    'value': chart[datasource]['values'][idx],
                    'as_name': asn_name + ' (AS' + asnum + ')',
                    'datasource': datasource,
                    'datetime': datetime.fromtimestamp(timestamp, timezone.utc),
                    'timestamp': timestamp,
                    'net_type': net_type
                })
                idx += 1
                timestamp += step
        sleep(1)

# In[ ]:
