import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const dir=process.argv[2]||'/repo/workflows';
const stable=v=>Array.isArray(v)?v.map(stable):v&&typeof v==='object'?Object.fromEntries(Object.keys(v).sort().filter(k=>!['active','createdAt','updatedAt','versionId','triggerCount','meta','shared','tags'].includes(k)).map(k=>[k,stable(v[k])])):v;
const files=fs.readdirSync(dir,{recursive:true}).filter(x=>String(x).endsWith('.json'));
const rows=[];
for(const f of files){const p=path.join(dir,String(f));let j=JSON.parse(fs.readFileSync(p,'utf8'));if(Array.isArray(j))for(const x of j)rows.push(x);else rows.push(j)}
const workflows=rows.map(w=>({id:w.id,name:w.name,canonical:JSON.stringify(stable({id:w.id,name:w.name,nodes:w.nodes,connections:w.connections,settings:w.settings}))})).sort((a,b)=>a.id.localeCompare(b.id));
const hashes=Object.fromEntries(workflows.map(w=>[w.id,crypto.createHash('sha256').update(w.canonical).digest('hex')]));
const combined=crypto.createHash('sha256').update(workflows.map(w=>w.id+':'+hashes[w.id]).join('\n')).digest('hex');
process.stdout.write(JSON.stringify({count:workflows.length,hashes,combinedSha256:combined,nodeTypes:[...new Set(rows.flatMap(w=>(w.nodes||[]).map(n=>n.type)))].sort()}));
