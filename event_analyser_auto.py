from pexpect import *
import sys
import os
import numpy as np


for inp_i in range(1): # give the total number of events to be run as range
  input_name='event_date_'+ str(inp_i+45)+'.txt' #starting event file

  f=open(input_name)
  f1=open('time.txt','w')
  f1.close()

  f2=open('anisotropy.txt','w')
  f2.close()

  txt_count=0;
  dir_name='event_analyser_output_'+ str(inp_i+45)#starting event file

  for f_dat in f:

    date=str(f_dat)
    yr=date[0:4]
    mn=date[5:7]
    day=date[8:10]
    hr=00
    mnt=00
    sec=00

    dt=mn+day+yr[2:4]
 
    times=['00:00:00']                    # enter the start time here   (default=0:0:0) 



    tra='[\''+ yr+'-'+mn+'-'+day+'/'+'00:00:00'+'\''  +','+'\''+yr+'-'+mn+'-'+day+'/'+'23:58:10'+'\']'

    p=spawn('idl',timeout=3600)
  #p.delaybeforesend=1
    p.logfile=sys.stdout
    p.expect('IDL>')
    p.sendline('@./wind_3dp_pros/start_umn_3dp.pro ')
    p.expect('UMN>')
    p.sendline('.compile get_3dp_structs.pro')
    p.expect('UMN>')

    p.sendline('date=\''+ dt + '\'' )
    p.expect('UMN>')
    p.sendline('duration=24')                      # enter the duration here (default =30 mins)
    p.expect('UMN>')



    p.sendline('tra='+tra)
    p.expect('UMN>')

    p.sendline('trange=time_double(tra)')
    p.expect('UMN>')
    p.sendline('memsize=150')
    p.expect('UMN>')



    p.sendline('file_mkdir,\''+ dir_name+'\' ')
    p.expect('UMN>')


    count=0
  
    for time in times:

      time_get=yr[2:4]+'-'+mn+'-'+day+'/'+time
      hr=time[0:2];
      mnt=time[3:5]
      p.sendline('load_3dp_data,\'' + time_get+ '\',duration,Quality=2,MEMSIZE=300')
      p.expect('UMN>')
      p.sendline('pesa_low_moment_calibrate,DATE=date,TRANGE=trange ')
      x1=int(p.expect(['UMN>','Please enter','No ion moments',TIMEOUT]))
      print p.before
      if x1!=0:
        print 'DATA MISSING!!!!!!!!!!!!!!!!!!!!!!'
        continue


# electron VDF start 


      p.sendline('dat1=get_3dp_structs(\'el\',TRANGE=trange) ')
      p.expect('UMN>')

      #p.delaybeforesend=0.1
      p.sendline(' ael=dat1.DATA')
      p.expect('UMN>')
      p.sendline('add_magf2,ael,\'wi_B3(GSE)\' ')
      p.expect('UMN>')
      p.sendline('add_vsw2,ael,\'V_sw2\' ')
      p.expect('UMN>')
      p.sendline('add_scpot,ael,\'sc_pot_2\' ')
      p.expect('UMN>')

      p.sendline('ar_size=size(ael)')
      p.expect('UMN>')

      p.sendline('total_plots=ar_size[1] ')
      p.expect('UMN>')
      p.sendline('print,total_plots')
      p.expect('UMN>') 
      asd=p.before 
      total_plots=np.arange(int(asd[len(asd)-5:len(asd)-1]))
     
      for number in total_plots:
        print number
        f_name= dir_name+'/evdf_'+yr+'_'+mn+'_'+day+'_'+str(number)
        txt_name=dir_name+'/'+ str(txt_count)
        p.sendline('el=ael['+str(number)+'] ')
        p.expect('UMN>')
        p.sendline('del=convert_vframe(el,/INTERP) ')
        p.expect('UMN>')    
        p.sendline('pd=pad(del,NUM_PA=17L) ')
        p.expect('UMN>')  
        p.sendline('df=distfunc(pd.ENERGY,pd.ANGLES,MASS=pd.MASS,DF=pd.DATA) ')
        p.expect('UMN>')   
        p.sendline('extract_tags, del,df ')
        p.expect('UMN>')    
        p.sendline('dat=el ')
        p.expect('UMN>')    
        p.sendline('dfra=[1e-17,1e-9] ')
        p.expect('UMN>')     


        p.sendline('cont2d_edited,\'/home/govind/data/wind/code/'+str(txt_name)+'\',del,VLIM=2d4,NGRID=30L,GNORM=gnoem,/HEAT_F,MYONEC=dat,DFRA=dfra ') 
        p.expect('UMN>')



        txt_count=txt_count+1
        txt_name=str(txt_count)



      count=count+1






    x=p.isalive()
    x=p.close()

  os.rename('anisotropy.txt','anisotropy_'+ str(inp_i+45)+'.txt')#starting event file

  os.rename('time.txt','time_'+ str(inp_i+45)+'.txt')  #starting event file



