"use client";

import { useEffect, useState, useCallback } from "react";
import { useSession, signIn, signOut } from "next-auth/react";
import { api } from "@/lib/api";
import type { CafeCard, ConditionResult } from "@/types";

const C = {
  ink:"#33272E",sub:"#7A6E75",faint:"#B4A9AF",
  surface:"#F8F3F5",card:"#FFFFFF",lavender:"#F4E9EF",line:"#EFE3E9",
  green:"#46B97A",greenDeep:"#34A267",
  rose:"#CE4A78",roseSoft:"#E0608A",pink:"#F3A0BE",pinkBg:"#FCE3EC",
  grad:"linear-gradient(135deg,#5FBE82 0%,#E6CBD6 50%,#E0608A 100%)",
};
const FM="var(--fm,ui-monospace,monospace)";

type Screen="welcome"|"login"|"connect"|"measure"|"state"|"location"|"cafes"|"detail"|"profile";
const ORDER:Screen[]=["welcome","login","connect","measure","state","location","cafes"];

function Dots({color="rgba(51,39,46,0.07)"}:{color?:string}){
  return <div style={{position:"absolute",inset:0,pointerEvents:"none",
    backgroundImage:`radial-gradient(${color} 1.4px,transparent 1.4px)`,backgroundSize:"22px 22px"}}/>;
}
function Kick({children,color=C.faint}:{children:React.ReactNode;color?:string}){
  return <div style={{fontFamily:FM,fontSize:11,fontWeight:500,letterSpacing:2,
    textTransform:"uppercase",color}}>{children}</div>;
}
function HeartSVG({size=20,color="#fff"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <path d="M12 20.5C12 20.5 3 14.6 3 8.7C3 5.9 5.2 4 7.6 4C9.3 4 10.9 4.9 12 6.5C13.1 4.9 14.7 4 16.4 4C18.8 4 21 5.9 21 8.7C21 14.6 12 20.5 12 20.5Z" fill={color}/>
  </svg>;
}
function PulseSVG({size=64,stroke=C.ink,sw=3.4}:{size?:number;stroke?:string;sw?:number}){
  return <svg width={size} height={size} viewBox="0 0 120 120" fill="none">
    <circle cx="60" cy="60" r="50" stroke={stroke} strokeWidth={sw} opacity="0.3"/>
    <path d="M22 60 H44 l7 -22 l11 44 l8 -30 l6 12 H98" stroke={stroke} strokeWidth={sw+0.6} strokeLinecap="round" strokeLinejoin="round"/>
  </svg>;
}
function CoffeeSVG({size=28,color="#33272E"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M18 8h1a4 4 0 0 1 0 8h-1"/>
    <path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z"/>
    <line x1="6" y1="1" x2="6" y2="4"/>
    <line x1="10" y1="1" x2="10" y2="4"/>
    <line x1="14" y1="1" x2="14" y2="4"/>
  </svg>;
}
function WatchSVG({size=22,color="#33272E"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <rect x="5" y="6" width="14" height="12" rx="3"/>
    <path d="M8 6V4a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v2"/>
    <path d="M8 18v2a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1v-2"/>
    <polyline points="10 11 12 13 14 10"/>
  </svg>;
}
function MapPinSVG({size=18,color="#33272E"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
    <circle cx="12" cy="10" r="3"/>
  </svg>;
}
function MapSVG({size=22,color="#33272E"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <polygon points="3 6 9 3 15 6 21 3 21 18 15 21 9 18 3 21"/>
    <line x1="9" y1="3" x2="9" y2="18"/>
    <line x1="15" y1="6" x2="15" y2="21"/>
  </svg>;
}
function NavigateSVG({size=18,color="#fff"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <polygon points="3 11 22 2 13 21 11 13 3 11"/>
  </svg>;
}
function DoorSVG({size=20,color="#CE4A78"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M13 4H6a1 1 0 0 0-1 1v15h14V5a1 1 0 0 0-1-1h-1"/>
    <path d="M14 4v16"/>
    <circle cx="16.5" cy="12" r="0.8" fill={color}/>
  </svg>;
}
function BulbSVG({size=18,color="#34A267"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M9 18h6M10 22h4M12 2a7 7 0 0 1 7 7c0 2.5-1.3 4.7-3.3 6H8.3C6.3 13.7 5 11.5 5 9a7 7 0 0 1 7-7z"/>
  </svg>;
}
function ShruggSVG({size=28,color="#B4A9AF"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="12" cy="8" r="3"/>
    <path d="M6.5 14c-.8-.4-1.5-.3-2 .5l-1 2"/>
    <path d="M17.5 14c.8-.4 1.5-.3 2 .5l1 2"/>
    <path d="M8 14l-.5 6h9l-.5-6"/>
    <path d="M8 14c1.2-.7 2.5-1 4-1s2.8.3 4 1"/>
  </svg>;
}
function StarSVG({size=16,color="#34A267"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
  </svg>;
}
// 모드별 아이콘 SVG
function FocusIconSVG({size=28,color="#34A267"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="12" cy="12" r="3"/>
    <path d="M12 2v2M12 20v2M2 12h2M20 12h2"/>
    <path d="M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M17.66 6.34l-1.41 1.41M6.34 17.66l-1.41 1.41"/>
  </svg>;
}
function DrowsyIconSVG({size=28,color="#7C5CB8"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
  </svg>;
}
function FatigueIconSVG({size=28,color="#CE4A78"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M22 12h-4l-3 9L9 3l-3 9H2"/>
  </svg>;
}
function EnergyIconSVG({size=28,color="#D48A00"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>
  </svg>;
}
function RecoveryIconSVG({size=28,color="#2E8B6A"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
  </svg>;
}
// 필터 태그 아이콘
function QuietSVG({size=14,color="#34A267"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/>
    <line x1="23" y1="9" x2="17" y2="15"/>
    <line x1="17" y1="9" x2="23" y2="15"/>
  </svg>;
}
function LaptopSVG({size=14,color="#34A267"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <rect x="2" y="4" width="20" height="13" rx="2"/>
    <path d="M1 21h22"/>
  </svg>;
}
function WifiSVG({size=14,color="#34A267"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M5 12.55a11 11 0 0 1 14.08 0"/>
    <path d="M1.42 9a16 16 0 0 1 21.16 0"/>
    <path d="M8.53 16.11a6 6 0 0 1 6.95 0"/>
    <circle cx="12" cy="20" r="1" fill={color} stroke="none"/>
  </svg>;
}
function PlugSVG({size=14,color="#34A267"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M12 22v-5"/>
    <path d="M9 8V2M15 8V2"/>
    <path d="M18 8H6l2 7h8l2-7z"/>
  </svg>;
}
function CoffeeBeamSVG({size=14,color="#34A267"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M18 8h1a4 4 0 0 1 0 8h-1"/>
    <path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z"/>
    <line x1="6" y1="1" x2="6" y2="4"/>
    <line x1="10" y1="1" x2="10" y2="4"/>
    <line x1="14" y1="1" x2="14" y2="4"/>
  </svg>;
}
function LeafSVG({size=14,color="#34A267"}:{size?:number;color?:string}){
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M17 8C8 10 5.9 16.17 3.82 19.34L5.71 21c2.21-2.68 5.67-8.5 11.29-7.17V19l8-8.5L17 2v6z"/>
  </svg>;
}
function GoogleG({size=20}:{size?:number}){
  return <svg width={size} height={size} viewBox="0 0 48 48">
    <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
    <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
    <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
    <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
  </svg>;
}
function Btn({label,onClick,bg=C.ink,color="#fff",sub,shadow=true}:
  {label:string;onClick?:()=>void;bg?:string;color?:string;sub?:React.ReactNode;shadow?:boolean}){
  return <div className="press" onClick={onClick} style={{height:56,borderRadius:18,background:bg,color,
    display:"flex",alignItems:"center",justifyContent:"center",gap:9,
    fontSize:17,fontWeight:600,letterSpacing:-0.2,
    boxShadow:shadow?"0 10px 26px rgba(42,35,66,0.18)":"none"}}>{sub}{label}</div>;
}
function TBtn({label,onClick,color=C.sub}:{label:string;onClick?:()=>void;color?:string}){
  return <div className="press" onClick={onClick} style={{textAlign:"center",
    fontSize:15,fontWeight:500,color,padding:"4px 0"}}>{label}</div>;
}
function BackBtn({onClick,dark=false}:{onClick:()=>void;dark?:boolean}){
  return <div className="press" onClick={onClick} style={{position:"absolute",top:58,left:18,zIndex:20,
    width:40,height:40,borderRadius:13,
    background:dark?"rgba(255,255,255,0.15)":"rgba(255,255,255,0.75)",
    backdropFilter:"blur(8px)",WebkitBackdropFilter:"blur(8px)",
    display:"flex",alignItems:"center",justifyContent:"center",
    boxShadow:"0 2px 8px rgba(0,0,0,0.08)"}}>
    <svg width="11" height="18" viewBox="0 0 11 18" fill="none">
      <path d="M9 2 L2 9 L9 16" stroke={dark?"#fff":C.ink} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  </div>;
}

function Device({children,dark=false}:{children:React.ReactNode;dark?:boolean}){
  const c=dark?"#fff":"#000";
  return (
    <div style={{width:372,height:806,borderRadius:48,overflow:"hidden",position:"relative",
      background:dark?"#000":C.surface,
      boxShadow:"0 40px 80px rgba(0,0,0,0.18),0 0 0 1px rgba(0,0,0,0.12)",flexShrink:0}}>
      <div style={{height:"100%",overflow:"hidden"}}>{children}</div>
    </div>
  );
}

function ScrWelcome({go}:{go:(s:Screen)=>void}){
  const {status}=useSession();
  useEffect(()=>{
    if(status==="authenticated") go("connect");
  },[status,go]);
  return (
    <div className="fs-screen" style={{height:"100%",display:"flex",flexDirection:"column",
      background:C.grad,position:"relative",overflow:"hidden"}}>
      <Dots/>
      <div style={{position:"absolute",top:-70,right:-60,width:220,height:220,borderRadius:"50%",background:"rgba(255,255,255,0.12)"}}/>
      <div style={{flex:1,display:"flex",flexDirection:"column",justifyContent:"center",padding:"0 34px",position:"relative",zIndex:2}}>
        <img src="/logo.svg" alt="FocusSpot" style={{width:96,height:96,marginBottom:32}}/>
        <Kick color="rgba(51,39,46,0.6)">FOCUSSPOT</Kick>
        <div style={{fontSize:38,fontWeight:700,lineHeight:"42px",color:C.ink,letterSpacing:-1.2,marginTop:16}}>
          오늘의 컨디션에<br/>맞는 카페를<br/>찾아드려요.
        </div>
        <div style={{fontSize:16,color:"rgba(51,39,46,0.65)",marginTop:18,lineHeight:"24px",maxWidth:290}}>
          Apple Watch의 심박 데이터를 읽어 지금 집중하기 좋은 공간을 추천해요.
        </div>
      </div>
      <div style={{padding:"0 24px 40px",position:"relative",zIndex:2,display:"flex",flexDirection:"column",gap:14}}>
        <Btn label="Google로 계속하기" onClick={()=>go("login")} bg="#fff" color="#1F1F1F" sub={<GoogleG size={20}/>}/>
        <div style={{fontSize:12.5,color:"rgba(51,39,46,0.55)",textAlign:"center",lineHeight:"18px"}}>
          계속하면 FocusSpot의 <b style={{fontWeight:600}}>약관</b>과 <b style={{fontWeight:600}}>개인정보 처리방침</b>에 동의하게 됩니다.
        </div>
      </div>
    </div>
  );
}

function ScrLogin({go,back}:{go:(s:Screen)=>void;back:()=>void}){
  const [sheet,setSheet]=useState(false);
  const {data:session,status}=useSession();
  useEffect(()=>{
    if(status==="authenticated") go("connect");
  },[status,go]);
  return (
    <div className="fs-screen" style={{height:"100%",display:"flex",flexDirection:"column",
      background:C.card,position:"relative",overflow:"hidden"}}>
      <BackBtn onClick={back}/>
      <div style={{flex:1,display:"flex",flexDirection:"column",justifyContent:"center",
        alignItems:"center",padding:"0 34px",textAlign:"center"}}>
        <img src="/logo.svg" alt="FocusSpot" style={{width:76,height:76,marginBottom:26}}/>
        <div style={{fontSize:26,fontWeight:700,color:C.ink,letterSpacing:-0.6}}>FocusSpot 시작하기</div>
        <div style={{fontSize:15.5,color:C.sub,marginTop:12,lineHeight:"23px",maxWidth:280}}>
          구글 계정으로 간편하게 로그인하세요. 별도 비밀번호는 필요 없어요.
        </div>
        <div style={{display:"flex",alignItems:"center",gap:8,marginTop:22,background:C.lavender,borderRadius:99,padding:"8px 14px"}}>
          <svg width="13" height="15" viewBox="0 0 13 15" fill="none">
            <path d="M6.5 1 L11.5 3 V7 C11.5 10.5 9 13 6.5 14 C4 13 1.5 10.5 1.5 7 V3 Z" stroke={C.greenDeep} strokeWidth="1.4" fill="none"/>
          </svg>
          <span style={{fontSize:12.5,fontWeight:500,color:C.greenDeep}}>FocusSpot은 비밀번호를 저장하지 않아요</span>
        </div>
      </div>
      <div style={{padding:"0 24px 44px",display:"flex",flexDirection:"column",gap:14}}>
        <Btn label="Google로 로그인" onClick={()=>setSheet(true)} bg="#fff" color="#1F1F1F" sub={<GoogleG size={20}/>}/>
        <div style={{fontSize:12.5,color:C.faint,textAlign:"center"}}>다른 로그인 방법은 제공하지 않아요</div>
      </div>
      <div onClick={()=>setSheet(false)} style={{position:"absolute",inset:0,zIndex:30,
        background:"rgba(20,12,16,0.42)",opacity:sheet?1:0,pointerEvents:sheet?"auto":"none",
        transition:"opacity .25s ease",display:"flex",alignItems:"flex-end"}}>
        <div onClick={e=>e.stopPropagation()} style={{width:"100%",background:"#fff",
          borderRadius:"24px 24px 0 0",padding:"12px 0 30px",
          transform:sheet?"translateY(0)":"translateY(100%)",
          transition:"transform .3s cubic-bezier(.4,0,.2,1)"}}>
          <div style={{width:40,height:5,borderRadius:3,background:"#E0DBE0",margin:"4px auto 14px"}}/>
          <div style={{display:"flex",alignItems:"center",gap:10,padding:"0 22px 14px",borderBottom:`1px solid ${C.line}`}}>
            <GoogleG size={22}/>
            <span style={{fontSize:15,fontWeight:600,color:"#1F1F1F"}}>계정 선택</span>
            <span style={{marginLeft:"auto",fontSize:13,color:C.faint}}>FocusSpot으로 로그인</span>
          </div>
          <div className="press" onClick={()=>signIn("google")}
            style={{display:"flex",alignItems:"center",gap:14,padding:"15px 22px"}}>
            <div style={{width:40,height:40,borderRadius:"50%",background:C.green,
              color:"#fff",display:"flex",alignItems:"center",justifyContent:"center",fontSize:17,fontWeight:700}}>
              {session?.user?.name?.[0]??"G"}
            </div>
            <div>
              <div style={{fontSize:15,fontWeight:600,color:C.ink}}>{session?.user?.name??"Google 계정으로 로그인"}</div>
              {session?.user?.email&&<div style={{fontSize:13,color:C.sub,marginTop:1}}>{session.user.email}</div>}
            </div>
          </div>
          <div className="press" onClick={()=>signIn("google")}
            style={{display:"flex",alignItems:"center",gap:14,padding:"15px 22px"}}>
            <div style={{width:40,height:40,borderRadius:"50%",border:`1.5px solid ${C.line}`,
              display:"flex",alignItems:"center",justifyContent:"center",color:C.sub,fontSize:22}}>+</div>
            <div style={{fontSize:15,fontWeight:600,color:C.ink}}>다른 계정 사용</div>
          </div>
        </div>
      </div>
    </div>
  );
}

function ScrConnect({go,back}:{go:(s:Screen)=>void;back:()=>void}){
  const perms=[
    ["심박수","실시간 BPM으로 각성·이완 상태를 파악해요"],
    ["심박 변이도 (HRV)","집중과 스트레스 정도를 측정해요"],
    ["활동 · 걸음","에너지 수준과 이동 패턴을 반영해요"],
  ];
  return (
    <div className="fs-screen" style={{height:"100%",display:"flex",flexDirection:"column",
      background:C.surface,paddingTop:110,position:"relative"}}>
      <BackBtn onClick={back}/>
      <div style={{padding:"0 28px"}}>
        <div style={{width:60,height:60,borderRadius:18,background:C.grad,display:"flex",alignItems:"center",
          justifyContent:"center",marginBottom:22,boxShadow:"0 10px 24px rgba(70,185,122,0.32)"}}>
          <HeartSVG size={28} color={C.ink}/>
        </div>
        <Kick>STEP 1 / 3</Kick>
        <div style={{fontSize:29,fontWeight:700,color:C.ink,letterSpacing:-0.7,marginTop:10,lineHeight:"33px"}}>
          Apple Watch를<br/>연결해주세요
        </div>
        <div style={{fontSize:15.5,color:C.sub,marginTop:12,lineHeight:"23px"}}>
          아래 데이터를 읽어 지금 컨디션을 분석해요. 데이터는 추천에만 쓰이고 기기에 안전하게 보관돼요.
        </div>
      </div>
      <div style={{padding:"26px 24px 0",display:"flex",flexDirection:"column",gap:10}}>
        {perms.map(([t,d],i)=>(
          <div key={i} style={{background:C.card,borderRadius:16,padding:"15px 16px",
            display:"flex",gap:13,alignItems:"flex-start",border:`1px solid ${C.line}`}}>
            <div style={{width:30,height:30,borderRadius:9,background:C.lavender,
              display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0,marginTop:1}}>
              <HeartSVG size={15} color={C.green}/>
            </div>
            <div>
              <div style={{fontSize:15,fontWeight:600,color:C.ink}}>{t}</div>
              <div style={{fontSize:13,color:C.sub,marginTop:3,lineHeight:"18px"}}>{d}</div>
            </div>
          </div>
        ))}
      </div>
      <div style={{flex:1}}/>
      <div style={{padding:"0 24px 40px",display:"flex",flexDirection:"column",gap:14}}>
        <Btn label="Apple Watch 연결" onClick={()=>go("measure")} sub={<WatchSVG size={18} color={C.ink}/>}/>
        <TBtn label="나중에 할게요" onClick={()=>go("measure")}/>
      </div>
    </div>
  );
}

function ScrMeasure({go,onCondition}:{go:(s:Screen)=>void;onCondition:(c:ConditionResult)=>void}){
  const [bpm,setBpm]=useState(78);
  const [pct,setPct]=useState(8);
  useEffect(()=>{
    const b=setInterval(()=>setBpm(70+Math.floor(Math.random()*8)),420);
    const p=setInterval(()=>setPct(v=>Math.min(100,v+6)),150);
    const done=setTimeout(async()=>{
      try{const c=await api.condition.current();if(c)onCondition(c);}catch(_){}
      go("state");
    },2800);
    return ()=>{clearInterval(b);clearInterval(p);clearTimeout(done);};
  },[go,onCondition]);
  return (
    <div className="fs-screen press" onClick={()=>go("state")} style={{height:"100%",
      display:"flex",flexDirection:"column",background:C.ink,position:"relative",overflow:"hidden"}}>
      <div style={{position:"absolute",inset:0,backgroundImage:"radial-gradient(rgba(255,255,255,0.06) 1.4px,transparent 1.4px)",backgroundSize:"22px 22px"}}/>
      <div style={{padding:"110px 28px 0",position:"relative",zIndex:2}}>
        <Kick color="rgba(255,255,255,0.55)">측정 중 · MEASURING</Kick>
        <div style={{fontSize:26,fontWeight:700,color:"#fff",letterSpacing:-0.6,marginTop:12}}>심박을 읽고 있어요</div>
      </div>
      <div style={{flex:1,display:"flex",flexDirection:"column",alignItems:"center",justifyContent:"center",position:"relative",zIndex:2}}>
        <div style={{position:"relative",width:220,height:220,display:"flex",alignItems:"center",justifyContent:"center"}}>
          <div style={{position:"absolute",inset:0,borderRadius:"50%",background:"radial-gradient(circle,rgba(70,185,122,0.35),transparent 70%)"}}/>
          <div style={{position:"absolute",width:180,height:180,borderRadius:"50%",border:"1.5px solid rgba(224,96,138,0.4)"}}/>
          <div className="fs-beat" style={{width:132,height:132,borderRadius:"50%",background:C.grad,
            display:"flex",alignItems:"center",justifyContent:"center",boxShadow:"0 0 50px rgba(224,96,138,0.5)"}}>
            <HeartSVG size={56} color={C.ink}/>
          </div>
        </div>
        <div style={{display:"flex",alignItems:"baseline",gap:6,marginTop:30}}>
          <span style={{fontFamily:FM,fontSize:52,fontWeight:700,color:"#fff",letterSpacing:-2}}>{bpm}</span>
          <span style={{fontFamily:FM,fontSize:15,color:C.pink}}>BPM</span>
        </div>
        <svg width="240" height="44" viewBox="0 0 240 44" fill="none" style={{marginTop:14}}>
          <path d="M0 22 H70 l9 -16 l12 32 l10 -26 l8 10 H150 l9 -18 l11 26 l8 -14 H240" stroke={C.pink} strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      </div>
      <div style={{padding:"0 28px 46px",position:"relative",zIndex:2}}>
        <div style={{height:5,borderRadius:4,background:"rgba(255,255,255,0.14)",overflow:"hidden"}}>
          <div style={{width:`${pct}%`,height:"100%",background:C.grad,borderRadius:4,transition:"width .15s linear"}}/>
        </div>
        <div style={{fontFamily:FM,fontSize:12.5,color:"rgba(255,255,255,0.6)",marginTop:12,textAlign:"center",letterSpacing:0.5}}>
          심박 변이도 분석 중… 잠시만요
        </div>
      </div>
    </div>
  );
}

function ScrState({go,condition}:{go:(s:Screen)=>void;condition:ConditionResult|null}){
  const label=condition?.label??"집중하기 좋은 상태예요 ✦";
  const hint=condition?.cafe_hint??"심박이 안정적이고 HRV가 높아요. 차분하고 조용한 공간에서 깊게 몰입하기 좋아요.";
  const score=condition?.confidence??82;
  const metrics:[string,string,string][]=[["72","BPM","안정"],["48","ms HRV","높음"],[String(score),"집중 점수","좋음"]];
  return (
    <div className="fs-screen" style={{height:"100%",display:"flex",flexDirection:"column",background:C.surface}}>
      <div style={{background:C.grad,padding:"108px 28px 30px",position:"relative",overflow:"hidden"}}>
        <Dots/>
        <div style={{position:"relative",zIndex:2}}>
          <Kick color="rgba(51,39,46,0.6)">지금 당신은</Kick>
          <div style={{fontSize:30,fontWeight:700,color:C.ink,letterSpacing:-0.8,marginTop:10,lineHeight:"34px"}}>{label}</div>
          <div style={{fontSize:15,color:"rgba(51,39,46,0.65)",marginTop:12,lineHeight:"22px"}}>{hint}</div>
        </div>
      </div>
      <div style={{display:"flex",gap:10,padding:"20px 24px 0"}}>
        {metrics.map(([v,l,tag],i)=>(
          <div key={i} style={{flex:1,background:C.card,borderRadius:16,padding:"15px 12px",border:`1px solid ${C.line}`,textAlign:"center"}}>
            <div style={{fontFamily:FM,fontSize:24,fontWeight:700,color:C.ink}}>{v}</div>
            <div style={{fontFamily:FM,fontSize:11,color:C.faint,marginTop:3,letterSpacing:0.3}}>{l}</div>
            <div style={{fontSize:11.5,fontWeight:600,color:C.rose,marginTop:8,background:C.pinkBg,borderRadius:8,padding:"3px 0"}}>{tag}</div>
          </div>
        ))}
      </div>
      <div style={{flex:1}}/>
      <div style={{padding:"0 24px 18px"}}>
        <div style={{background:C.lavender,borderRadius:14,padding:"13px 16px",display:"flex",gap:10,alignItems:"center"}}>
          <BulbSVG size={17} color={C.greenDeep}/>
          <span style={{fontSize:13.5,fontWeight:500,color:C.greenDeep,lineHeight:"19px"}}>조용함 · 콘센트 · 넓은 좌석 위주로 추천할게요</span>
        </div>
      </div>
      <div style={{padding:"0 24px 40px"}}><Btn label="카페 추천 보기" onClick={()=>go("location")}/></div>
    </div>
  );
}

function ScrLocation({go,back,onLocation}:{go:(s:Screen)=>void;back:()=>void;onLocation:(lat:number,lng:number)=>void}){
  const [geoError,setGeoError]=useState<string|null>(null);
  const [loading,setLoading]=useState(false);

  const allow=()=>{
    setLoading(true);
    setGeoError(null);
    navigator.geolocation.getCurrentPosition(
      p=>{setLoading(false);onLocation(p.coords.latitude,p.coords.longitude);go("cafes");},
      e=>{
        setLoading(false);
        const msg=e.code===1?"위치 권한이 차단되어 있어요. 브라우저 주소창 옆 자물쇠를 클릭해 위치 권한을 허용해주세요."
          :e.code===3?"위치를 가져오는 데 시간이 너무 걸려요. 다시 시도해주세요."
          :"위치를 가져올 수 없어요.";
        setGeoError(msg);
      },
      {timeout:10000,enableHighAccuracy:true}
    );
  };
  return (
    <div className="fs-screen" style={{height:"100%",display:"flex",flexDirection:"column",background:C.surface,position:"relative"}}>
      <BackBtn onClick={back}/>
      <div style={{height:392,background:C.lavender,position:"relative",overflow:"hidden",flexShrink:0}}>
        <div style={{position:"absolute",inset:0,backgroundImage:`linear-gradient(rgba(70,185,122,0.10) 1px,transparent 1px),linear-gradient(90deg,rgba(70,185,122,0.10) 1px,transparent 1px)`,backgroundSize:"44px 44px"}}/>
        <div style={{position:"absolute",top:130,left:-20,right:-20,height:20,background:"#fff",transform:"rotate(-7deg)",opacity:0.92}}/>
        <div style={{position:"absolute",top:30,bottom:30,left:130,width:20,background:"#fff",transform:"rotate(5deg)",opacity:0.92}}/>
        <div style={{position:"absolute",bottom:80,left:-20,right:-20,height:14,background:"#fff",transform:"rotate(3deg)",opacity:0.8}}/>
        <div style={{position:"absolute",top:80,left:56,width:13,height:13,borderRadius:"50%",background:C.roseSoft,border:"3px solid #fff",boxShadow:"0 2px 6px rgba(0,0,0,0.2)"}}/>
        <div style={{position:"absolute",top:250,left:250,width:13,height:13,borderRadius:"50%",background:C.roseSoft,border:"3px solid #fff",boxShadow:"0 2px 6px rgba(0,0,0,0.2)"}}/>
        <div style={{position:"absolute",top:"50%",left:"50%",transform:"translate(-50%,-100%)"}}>
          <div style={{width:60,height:60,borderRadius:"50% 50% 50% 4px",background:C.grad,transform:"rotate(45deg)",
            display:"flex",alignItems:"center",justifyContent:"center",boxShadow:"0 12px 26px rgba(52,162,103,0.4)"}}>
            <div style={{transform:"rotate(-45deg)"}}><HeartSVG size={24} color={C.ink}/></div>
          </div>
        </div>
      </div>
      <div style={{flex:1,display:"flex",flexDirection:"column",padding:"28px 28px 0"}}>
        <Kick>STEP 3 / 3</Kick>
        <div style={{fontSize:28,fontWeight:700,color:C.ink,letterSpacing:-0.7,marginTop:10,lineHeight:"32px"}}>근처 카페를<br/>찾을게요</div>
        <div style={{fontSize:15.5,color:C.sub,marginTop:12,lineHeight:"23px"}}>위치를 켜면 지금 컨디션에 맞는 카페를 가까운 순으로 보여드려요.</div>
        {geoError&&(
          <div style={{marginTop:16,background:"#FFF0F0",border:"1px solid #F8CCCC",borderRadius:14,padding:"12px 16px",
            fontSize:13,color:"#B03030",lineHeight:"19px"}}>
            {geoError}
          </div>
        )}
        <div style={{flex:1}}/>
        <div style={{display:"flex",flexDirection:"column",gap:14,paddingBottom:40}}>
          <Btn label={loading?"위치 확인 중…":"위치 허용"} onClick={loading?undefined:allow}
            bg={loading?C.faint:C.ink}/>
          <TBtn label="지금은 안 할게요" onClick={()=>{onLocation(37.4979,127.0276);go("cafes");}}/>
        </div>
      </div>
    </div>
  );
}

const NL:Record<string,{label:string;Icon:React.FC<{size?:number;color?:string}>}>={quiet:{label:"조용함",Icon:QuietSVG},"moderate-noise":{label:"보통",Icon:WifiSVG},lively:{label:"활기참",Icon:EnergyIconSVG}};
const WL:Record<string,{label:string;Icon:React.FC<{size?:number;color?:string}>}>={"work-friendly":{label:"업무 가능",Icon:LaptopSVG},"fast-wifi":{label:"빠른 와이파이",Icon:WifiSVG},"power-outlet":{label:"콘센트",Icon:PlugSVG},"easy-to-seat":{label:"자리 여유",Icon:StarSVG},"specialty-coffee":{label:"스페셜티",Icon:CoffeeBeamSVG},"decaf-available":{label:"디카페인",Icon:LeafSVG}};
type NLEntry={label:string;Icon:React.FC<{size?:number;color?:string}>};
function NoiseBadge({nl,size=11,pad="4px 9px",radius=7}:{nl:NLEntry;size?:number;pad?:string;radius?:number}){
  return <span style={{fontSize:size+0.5,fontWeight:500,color:C.greenDeep,background:C.lavender,borderRadius:radius,padding:pad,display:"flex",alignItems:"center",gap:4}}>
    <nl.Icon size={size} color={C.greenDeep}/>{nl.label}
  </span>;
}
function WorkBadge({wl,size=11,pad="4px 9px",radius=7}:{wl:NLEntry;size?:number;pad?:string;radius?:number}){
  return <span style={{fontSize:size+0.5,fontWeight:500,color:C.greenDeep,background:C.lavender,borderRadius:radius,padding:pad,display:"flex",alignItems:"center",gap:4}}>
    <wl.Icon size={size} color={C.greenDeep}/>{wl.label}
  </span>;
}

function ScrCafes({cafes,loading,openCafe,condition,go}:{cafes:CafeCard[];loading:boolean;openCafe:(c:CafeCard)=>void;condition:ConditionResult|null;go:(s:Screen)=>void}){
  const {data:session}=useSession();
  const modeLabel=condition?.mode==="focus"?"집중":condition?.mode==="drowsy"?"졸림":condition?.mode==="fatigue"?"피로":condition?.mode==="energized"?"활기":"회복";
  return (
    <div className="fs-screen" style={{height:"100%",display:"flex",flexDirection:"column",background:C.surface}}>
      <div style={{padding:"52px 24px 18px",background:C.card,borderBottom:`1px solid ${C.line}`}}>
        <div style={{display:"flex",justifyContent:"space-between",alignItems:"flex-start"}}>
          <div>
            <div style={{fontSize:24,fontWeight:700,color:C.ink,letterSpacing:-0.6}}>추천 카페</div>
            <div style={{fontSize:14,color:C.sub,marginTop:4}}>지금 컨디션에 딱 맞는 곳</div>
          </div>
          <div style={{display:"flex",alignItems:"center",gap:10}}>
            {condition&&(
              <div style={{display:"flex",alignItems:"center",gap:7,background:C.pinkBg,borderRadius:99,padding:"7px 12px"}}>
                <HeartSVG size={13} color={C.rose}/>
                <span style={{fontFamily:FM,fontSize:12.5,fontWeight:600,color:C.rose}}>{modeLabel}</span>
              </div>
            )}
            <div className="press" onClick={()=>go("profile")} style={{width:36,height:36,borderRadius:"50%",overflow:"hidden",
              border:`2px solid ${C.line}`,flexShrink:0}}>
              {session?.user?.image
                ? <img src={session.user.image} alt="" style={{width:"100%",height:"100%",objectFit:"cover"}}/>
                : <div style={{width:"100%",height:"100%",background:C.grad,display:"flex",alignItems:"center",justifyContent:"center",fontSize:14,fontWeight:700,color:"#fff"}}>
                    {session?.user?.name?.[0]??"U"}
                  </div>
              }
            </div>
          </div>
        </div>
      </div>
      <div style={{flex:1,padding:"16px 20px",display:"flex",flexDirection:"column",gap:13,overflowY:"auto"}}>
        {loading&&(
          <div style={{display:"flex",alignItems:"center",justifyContent:"center",flex:1,flexDirection:"column",gap:16}}>
            <div className="fs-beat"><HeartSVG size={40} color={C.green}/></div>
            <span style={{fontFamily:FM,fontSize:12,color:C.faint,letterSpacing:1}}>SEARCHING…</span>
          </div>
        )}
        {!loading&&cafes.length===0&&(
          <div style={{textAlign:"center",color:C.sub,paddingTop:60,fontSize:15,lineHeight:"24px"}}>
            주변 카페를 찾지 못했어요.<br/>반경을 넓혀보세요.
          </div>
        )}
        {cafes.map((c,i)=>(
          <div key={c.id} className="press" onClick={()=>openCafe(c)} style={{background:C.card,borderRadius:18,padding:14,
            border:`1px solid ${i===0?C.green:C.line}`,display:"flex",gap:13,
            boxShadow:i===0?"0 10px 26px rgba(70,185,122,0.16)":"none"}}>
            <div style={{width:64,height:64,borderRadius:14,flexShrink:0,
              background:i===0?C.grad:C.lavender,display:"flex",alignItems:"center",justifyContent:"center"}}>
              <CoffeeSVG size={26} color={i===0?"#fff":C.greenDeep}/>
            </div>
            <div style={{flex:1,minWidth:0}}>
              <div style={{display:"flex",alignItems:"center",gap:7,flexWrap:"wrap"}}>
                <span style={{fontSize:16,fontWeight:700,color:C.ink}}>{c.name}</span>
                {i===0&&<span style={{fontFamily:FM,fontSize:10,fontWeight:600,color:"#fff",background:C.green,borderRadius:6,padding:"2px 6px",letterSpacing:0.3}}>BEST</span>}
              </div>
              <div style={{fontFamily:FM,fontSize:12,color:C.faint,marginTop:3}}>
                {c.distance_m<1000?`${c.distance_m}m`:`${(c.distance_m/1000).toFixed(1)}km`}
              </div>
              <div style={{display:"flex",gap:6,marginTop:9,flexWrap:"wrap"}}>
                {c.noise_level&&NL[c.noise_level]&&<NoiseBadge nl={NL[c.noise_level]} size={11}/>}
                {c.work_tags.slice(0,2).map(t=>WL[t]?<WorkBadge key={t} wl={WL[t]} size={11}/>:null)}
              </div>
            </div>
            <div style={{textAlign:"right",flexShrink:0}}>
              <div style={{fontFamily:FM,fontSize:19,fontWeight:700,color:C.rose}}>{c.match_pct}</div>
              <div style={{fontFamily:FM,fontSize:9.5,color:C.faint,letterSpacing:0.4}}>MATCH %</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

const MODE_META:{[k:string]:{label:string;Icon:React.FC<{size?:number;color?:string}>;color:string;bg:string;desc:string}}={
  focus:    {label:"집중 모드",Icon:FocusIconSVG,  color:C.greenDeep,bg:C.lavender,   desc:"수면·심박 모두 안정적이에요. 지금이 가장 집중하기 좋은 상태예요."},
  drowsy:   {label:"졸림 모드",Icon:DrowsyIconSVG, color:"#7C5CB8",  bg:"#F0EBF8",    desc:"수면이 조금 부족해 보여요. 밝고 약간 소음 있는 카페가 도움돼요."},
  fatigue:  {label:"피로 모드",Icon:FatigueIconSVG,color:C.rose,     bg:C.pinkBg,     desc:"심박이 높고 피로도가 쌓여 있어요. 조용하고 편안한 공간을 추천해요."},
  energized:{label:"활기 모드",Icon:EnergyIconSVG, color:"#D48A00",  bg:"#FFF6DC",    desc:"에너지가 넘쳐요! 활기차고 사람 많은 카페도 잘 맞아요."},
  recovery: {label:"회복 모드",Icon:RecoveryIconSVG,color:"#2E8B6A", bg:"#E6F5EE",   desc:"불규칙한 패턴이 감지됐어요. 조용하고 개인 공간 있는 곳을 찾아보세요."},
};

const RADIUS_OPTIONS=[500,1000,2000] as const;
type RadiusOption=typeof RADIUS_OPTIONS[number];
const CAFE_FILTER_TAGS=["quiet","work-friendly","fast-wifi","power-outlet","specialty-coffee","decaf-available"] as const;
type CafeFilterTag=typeof CAFE_FILTER_TAGS[number];
const FILTER_LABEL:Record<CafeFilterTag,{label:string;Icon:React.FC<{size?:number;color?:string}>}>={"quiet":{label:"조용함",Icon:QuietSVG},"work-friendly":{label:"업무 가능",Icon:LaptopSVG},"fast-wifi":{label:"빠른 와이파이",Icon:WifiSVG},"power-outlet":{label:"콘센트",Icon:PlugSVG},"specialty-coffee":{label:"스페셜티",Icon:CoffeeBeamSVG},"decaf-available":{label:"디카페인",Icon:LeafSVG}};

function ScrProfile({back,condition,radius,setRadius}:{back:()=>void;condition:ConditionResult|null;radius:RadiusOption;setRadius:(r:RadiusOption)=>void}){
  const {data:session}=useSession();
  const meta=condition?MODE_META[condition.mode]:null;
  const [filters,setFilters]=useState<Set<CafeFilterTag>>(new Set());
  const [watchConnected]=useState(condition!==null);

  const toggleFilter=(tag:CafeFilterTag)=>setFilters(prev=>{
    const next=new Set(prev);
    next.has(tag)?next.delete(tag):next.add(tag);
    return next;
  });

  return (
    <div className="fs-screen" style={{height:"100%",display:"flex",flexDirection:"column",background:C.surface,overflowY:"auto"}}>
      <BackBtn onClick={back}/>
      <div style={{padding:"80px 24px 32px",display:"flex",flexDirection:"column",gap:20}}>
        {/* 프로필 */}
        <div style={{display:"flex",alignItems:"center",gap:16}}>
          {session?.user?.image
            ? <img src={session.user.image} alt="" style={{width:64,height:64,borderRadius:"50%",border:`2px solid ${C.line}`,flexShrink:0}}/>
            : <div style={{width:64,height:64,borderRadius:"50%",background:C.grad,display:"flex",alignItems:"center",justifyContent:"center",fontSize:26,fontWeight:700,color:"#fff",flexShrink:0}}>
                {session?.user?.name?.[0]??"U"}
              </div>
          }
          <div>
            <div style={{fontSize:18,fontWeight:700,color:C.ink}}>{session?.user?.name??"사용자"}</div>
            <div style={{fontSize:13,color:C.sub,marginTop:2}}>{session?.user?.email??""}</div>
          </div>
        </div>

        {/* 현재 컨디션 */}
        <div>
          <div style={{fontSize:12,fontWeight:600,color:C.faint,letterSpacing:1.5,textTransform:"uppercase",marginBottom:10}}>현재 내 상태</div>
          {meta&&condition?(
            <div style={{background:meta.bg,borderRadius:20,padding:20,border:`1px solid ${meta.color}22`}}>
              <div style={{display:"flex",alignItems:"center",gap:12,marginBottom:14}}>
                <div style={{width:44,height:44,borderRadius:13,background:"rgba(255,255,255,0.6)",display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}>
                  <meta.Icon size={24} color={meta.color}/>
                </div>
                <div>
                  <div style={{fontSize:17,fontWeight:700,color:meta.color}}>{meta.label}</div>
                  <div style={{fontSize:13,color:C.sub,marginTop:2}}>{meta.desc}</div>
                </div>
              </div>
              {/* 신뢰도 바 */}
              <div>
                <div style={{display:"flex",justifyContent:"space-between",marginBottom:6}}>
                  <span style={{fontSize:12,color:C.sub}}>측정 신뢰도</span>
                  <span style={{fontSize:12,fontWeight:700,color:meta.color,fontFamily:FM}}>{condition.confidence}%</span>
                </div>
                <div style={{height:6,background:"rgba(0,0,0,0.07)",borderRadius:99,overflow:"hidden"}}>
                  <div style={{height:"100%",width:`${condition.confidence}%`,background:meta.color,borderRadius:99,transition:"width .6s ease"}}/>
                </div>
              </div>
              {/* 건강 수치 */}
              {(condition.heart_rate||condition.sleep_hours||condition.spo2||condition.step_count)&&(
                <div style={{display:"flex",gap:8,marginTop:14,flexWrap:"wrap"}}>
                  {condition.heart_rate&&(
                    <div style={{flex:1,minWidth:60,background:"rgba(255,255,255,0.65)",borderRadius:14,padding:"10px 12px",textAlign:"center"}}>
                      <div style={{fontFamily:FM,fontSize:18,fontWeight:700,color:meta.color,lineHeight:1}}>{condition.heart_rate}</div>
                      <div style={{fontSize:10,color:C.sub,marginTop:4}}>BPM</div>
                    </div>
                  )}
                  {condition.sleep_hours&&(
                    <div style={{flex:1,minWidth:60,background:"rgba(255,255,255,0.65)",borderRadius:14,padding:"10px 12px",textAlign:"center"}}>
                      <div style={{fontFamily:FM,fontSize:18,fontWeight:700,color:meta.color,lineHeight:1}}>{condition.sleep_hours.toFixed(1)}</div>
                      <div style={{fontSize:10,color:C.sub,marginTop:4}}>수면(h)</div>
                    </div>
                  )}
                  {condition.spo2&&(
                    <div style={{flex:1,minWidth:60,background:"rgba(255,255,255,0.65)",borderRadius:14,padding:"10px 12px",textAlign:"center"}}>
                      <div style={{fontFamily:FM,fontSize:18,fontWeight:700,color:meta.color,lineHeight:1}}>{condition.spo2}</div>
                      <div style={{fontSize:10,color:C.sub,marginTop:4}}>SpO2 %</div>
                    </div>
                  )}
                  {condition.step_count&&(
                    <div style={{flex:1,minWidth:60,background:"rgba(255,255,255,0.65)",borderRadius:14,padding:"10px 12px",textAlign:"center"}}>
                      <div style={{fontFamily:FM,fontSize:18,fontWeight:700,color:meta.color,lineHeight:1}}>{condition.step_count.toLocaleString()}</div>
                      <div style={{fontSize:10,color:C.sub,marginTop:4}}>걸음</div>
                    </div>
                  )}
                </div>
              )}
            </div>
          ):(
            <div style={{background:C.card,borderRadius:20,padding:20,border:`1px solid ${C.line}`,
              display:"flex",alignItems:"center",gap:14}}>
              <ShruggSVG size={28} color={C.faint}/>
              <div style={{fontSize:14,color:C.sub,lineHeight:"20px"}}>아직 컨디션 측정 전이에요.<br/>측정 후 여기서 상태를 확인할 수 있어요.</div>
            </div>
          )}
        </div>

        {/* iOS 연결 상태 */}
        <div>
          <div style={{fontSize:12,fontWeight:600,color:C.faint,letterSpacing:1.5,textTransform:"uppercase",marginBottom:10}}>기기 연결</div>
          <div style={{background:C.card,borderRadius:18,border:`1px solid ${C.line}`,padding:"16px 20px",display:"flex",alignItems:"center",justifyContent:"space-between"}}>
            <div style={{display:"flex",alignItems:"center",gap:12}}>
              <div style={{width:40,height:40,borderRadius:12,background:watchConnected?C.lavender:"#F5F5F5",
                display:"flex",alignItems:"center",justifyContent:"center"}}>
                <WatchSVG size={20} color={watchConnected?C.greenDeep:C.faint}/>
              </div>
              <div>
                <div style={{fontSize:15,fontWeight:600,color:C.ink}}>Apple Watch</div>
                <div style={{fontSize:12,color:watchConnected?C.greenDeep:C.faint,marginTop:2,fontWeight:500}}>
                  {watchConnected?"연결됨 · 데이터 동기화 중":"연결 안 됨"}
                </div>
              </div>
            </div>
            <div style={{width:10,height:10,borderRadius:"50%",background:watchConnected?C.green:"#D0CDD0",
              boxShadow:watchConnected?`0 0 0 3px ${C.green}33`:"none",flexShrink:0}}/>
          </div>
        </div>

        {/* 위치 반경 설정 */}
        <div>
          <div style={{fontSize:12,fontWeight:600,color:C.faint,letterSpacing:1.5,textTransform:"uppercase",marginBottom:10}}>검색 반경</div>
          <div style={{background:C.card,borderRadius:18,border:`1px solid ${C.line}`,padding:"16px 20px"}}>
            <div style={{display:"flex",alignItems:"center",gap:8,marginBottom:14}}>
              <MapPinSVG size={16} color={C.sub}/>
              <span style={{fontSize:14,color:C.sub}}>주변 카페를 찾을 거리를 설정하세요</span>
            </div>
            <div style={{display:"flex",gap:8}}>
              {RADIUS_OPTIONS.map(r=>(
                <div key={r} className="press" onClick={()=>setRadius(r)}
                  style={{flex:1,height:42,borderRadius:13,border:`1.5px solid ${radius===r?C.green:C.line}`,
                    background:radius===r?C.lavender:C.surface,
                    display:"flex",alignItems:"center",justifyContent:"center",
                    fontFamily:FM,fontSize:13,fontWeight:600,
                    color:radius===r?C.greenDeep:C.sub,transition:"all .18s ease"}}>
                  {r<1000?`${r}m`:`${r/1000}km`}
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* 선호 카페 필터 */}
        <div>
          <div style={{fontSize:12,fontWeight:600,color:C.faint,letterSpacing:1.5,textTransform:"uppercase",marginBottom:10}}>선호 카페 타입</div>
          <div style={{background:C.card,borderRadius:18,border:`1px solid ${C.line}`,padding:"16px 20px"}}>
            <div style={{display:"flex",alignItems:"center",gap:8,marginBottom:14}}>
              <StarSVG size={16} color={C.sub}/>
              <span style={{fontSize:14,color:C.sub}}>선택하면 추천 우선순위에 반영돼요</span>
            </div>
            <div style={{display:"flex",flexWrap:"wrap",gap:8}}>
              {CAFE_FILTER_TAGS.map(tag=>{
                const on=filters.has(tag);
                const{label,Icon}=FILTER_LABEL[tag];
                return (
                  <div key={tag} className="press" onClick={()=>toggleFilter(tag)}
                    style={{borderRadius:10,border:`1.5px solid ${on?C.green:C.line}`,
                      background:on?C.lavender:C.surface,
                      padding:"8px 13px",
                      fontSize:13,fontWeight:500,
                      color:on?C.greenDeep:C.sub,
                      display:"flex",alignItems:"center",gap:5,
                      transition:"all .18s ease"}}>
                    <Icon size={13} color={on?C.greenDeep:C.sub}/>{label}
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        {/* 계정 */}
        <div>
          <div style={{fontSize:12,fontWeight:600,color:C.faint,letterSpacing:1.5,textTransform:"uppercase",marginBottom:10}}>계정</div>
          <div style={{background:C.card,borderRadius:18,border:`1px solid ${C.line}`,overflow:"hidden"}}>
            <div className="press" onClick={()=>signOut()} style={{display:"flex",alignItems:"center",justifyContent:"space-between",padding:"16px 20px"}}>
              <div style={{display:"flex",alignItems:"center",gap:12}}>
                <DoorSVG size={20} color={C.rose}/>
                <span style={{fontSize:15,fontWeight:500,color:C.rose}}>로그아웃</span>
              </div>
              <svg width="8" height="13" viewBox="0 0 8 13" fill="none">
                <path d="M1 1.5 L6 6.5 L1 11.5" stroke={C.faint} strokeWidth="2" strokeLinecap="round"/>
              </svg>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function ScrDetail({cafe,back}:{cafe:CafeCard;back:()=>void}){
  return (
    <div className="fs-screen" style={{height:"100%",display:"flex",flexDirection:"column",background:C.surface,position:"relative"}}>
      <BackBtn onClick={back}/>
      <div style={{height:210,background:C.grad,position:"relative",overflow:"hidden",flexShrink:0}}>
        <Dots/>
        <div style={{position:"absolute",bottom:18,right:22,opacity:0.9}}>
          <CoffeeSVG size={78} color="rgba(51,39,46,0.55)"/>
        </div>
        <div className="press" style={{position:"absolute",top:58,right:18,width:40,height:40,borderRadius:13,
          background:"rgba(255,255,255,0.75)",backdropFilter:"blur(8px)",
          display:"flex",alignItems:"center",justifyContent:"center",boxShadow:"0 2px 8px rgba(0,0,0,0.08)"}}>
          <HeartSVG size={18} color={C.rose}/>
        </div>
      </div>
      <div style={{flex:1,overflowY:"auto",padding:"20px 24px 120px"}}>
        <div style={{fontSize:25,fontWeight:700,color:C.ink,letterSpacing:-0.6}}>{cafe.name}</div>
        <div style={{fontSize:14,color:C.sub,marginTop:6,display:"flex",alignItems:"center",gap:8}}>
          <span>{cafe.address}</span>
          <span style={{color:C.line}}>|</span>
          <span style={{color:C.greenDeep,fontWeight:600}}>
            {cafe.distance_m<1000?`${cafe.distance_m}m`:`${(cafe.distance_m/1000).toFixed(1)}km`}
          </span>
        </div>
        <div style={{background:C.card,border:`1px solid ${C.line}`,borderRadius:18,padding:16,marginTop:18}}>
          <div style={{display:"flex",alignItems:"center",gap:10}}>
            <div style={{width:46,height:46,borderRadius:12,background:C.pinkBg,
              display:"flex",flexDirection:"column",alignItems:"center",justifyContent:"center",flexShrink:0}}>
              <span style={{fontFamily:FM,fontSize:16,fontWeight:700,color:C.rose,lineHeight:1}}>{cafe.match_pct}</span>
              <span style={{fontFamily:FM,fontSize:8,color:C.rose,letterSpacing:0.3}}>MATCH %</span>
            </div>
            <div style={{fontSize:15,fontWeight:700,color:C.ink}}>지금 당신에게<br/>{cafe.match_pct}% 잘 맞아요</div>
          </div>
          <div style={{display:"flex",gap:9,marginTop:14,padding:"12px 13px",background:C.lavender,borderRadius:13}}>
            <HeartSVG size={15} color={C.green}/>
            <span style={{fontSize:13,fontWeight:500,color:C.greenDeep,lineHeight:"19px"}}>{cafe.recommendation_reason}</span>
          </div>
        </div>
        <div style={{display:"flex",gap:6,marginTop:16,flexWrap:"wrap"}}>
          {cafe.noise_level&&NL[cafe.noise_level]&&<NoiseBadge nl={NL[cafe.noise_level]} size={12} pad="5px 11px" radius={8}/>}
          {cafe.work_tags.slice(0,4).map(t=>WL[t]?<WorkBadge key={t} wl={WL[t]} size={12} pad="5px 11px" radius={8}/>:null)}
        </div>
      </div>
      <div style={{position:"absolute",left:0,right:0,bottom:0,padding:"14px 24px 30px",
        background:`linear-gradient(to top,${C.surface} 72%,transparent)`,display:"flex",gap:12}}>
        {cafe.kakao_url&&(
          <a href={cafe.kakao_url} target="_blank" rel="noopener noreferrer" className="press"
            style={{width:56,height:56,borderRadius:18,background:C.card,border:`1px solid ${C.line}`,
              display:"flex",alignItems:"center",justifyContent:"center"}}><MapSVG size={22} color={C.ink}/></a>
        )}
        <div style={{flex:1}}>
          <Btn label="길찾기 시작" sub={<NavigateSVG size={16} color="#fff"/>}
            onClick={()=>cafe.kakao_url&&window.open(cafe.kakao_url,"_blank")}/>
        </div>
      </div>
    </div>
  );
}

export default function App(){
  const {data:session,status}=useSession();
  const [stack,setStack]=useState<Screen[]>(["welcome"]);
  const [condition,setCondition]=useState<ConditionResult|null>(null);
  const [cafes,setCafes]=useState<CafeCard[]>([]);
  const [cafesLoading,setCafesLoading]=useState(false);
  const [selectedCafe,setSelectedCafe]=useState<CafeCard|null>(null);
  const [radius,setRadius]=useState<RadiusOption>(1000);

  const cur=stack[stack.length-1];
  const go=useCallback((s:Screen)=>setStack(p=>[...p,s]),[]);
  const back=useCallback(()=>setStack(p=>p.length>1?p.slice(0,-1):p),[]);

  const handleCondition=useCallback((c:ConditionResult)=>setCondition(c),[]);

  const handleLocation=useCallback(async(lat:number,lng:number)=>{
    setCafesLoading(true);
    try{const r=await api.cafes.recommend(lat,lng,radius/1000);setCafes(r.cafes);}
    catch(_){setCafes([]);}
    finally{setCafesLoading(false);}
  },[radius]);

  const openCafe=useCallback((c:CafeCard)=>{setSelectedCafe(c);go("detail");},[go]);

  const isDark=cur==="measure";

  const screen=()=>{
    if(status==="unauthenticated"&&["connect","measure","state","location","cafes","detail"].includes(cur)){
      return <ScrLogin go={go} back={back}/>;
    }
    switch(cur){
      case "welcome":  return <ScrWelcome go={go}/>;
      case "login":    return <ScrLogin go={go} back={back}/>;
      case "connect":  return <ScrConnect go={go} back={back}/>;
      case "measure":  return <ScrMeasure go={go} onCondition={handleCondition}/>;
      case "state":    return <ScrState go={go} condition={condition}/>;
      case "location": return <ScrLocation go={go} back={back} onLocation={handleLocation}/>;
      case "cafes":    return <ScrCafes cafes={cafes} loading={cafesLoading} openCafe={openCafe} condition={condition} go={go}/>;
      case "detail":   return selectedCafe?<ScrDetail cafe={selectedCafe} back={back}/>:<ScrCafes cafes={cafes} loading={false} openCafe={openCafe} condition={condition} go={go}/>;
      case "profile":  return <ScrProfile back={back} condition={condition} radius={radius} setRadius={setRadius}/>;
    }
  };

  return (
    <div style={{display:"flex",flexDirection:"column",alignItems:"center",gap:22}}>
      <Device dark={isDark}>
        <div key={cur} style={{height:"100%"}}>{screen()}</div>
      </Device>
    </div>
  );
}
