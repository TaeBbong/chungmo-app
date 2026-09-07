// Client-rendered invitation: the HTML above is an empty shell, everything
// comes from data.json at runtime (what a Vite/CRA SPA vendor ships).
const root = document.getElementById('root');
fetch('./data.json').then(r => r.json()).then(d => {
  const g = d.couple.groom, b = d.couple.bride, v = d.venue;
  const accs = ['groom', 'bride'].map(side => d.accounts[side].map(a =>
    `<li>${a.bank} ${a.number} (${a.holder})</li>`).join('')).join('');
  root.innerHTML = `
    <main class="card">
      <img src="./main.svg" alt="">
      <h1>${g.name} <small>&amp;</small> ${b.name}</h1>
      <p class="date">${d.dateText || '일정 추후 공지'}</p>
      <p class="venue">${v.name} ${v.hall}</p>
      <p class="greeting">${d.greeting}</p>
      <p class="parents">${g.father} · ${g.mother}의 ${g.order} ${g.name.slice(1)}<br>${b.father} · ${b.mother}의 ${b.order} ${b.name.slice(1)}</p>
      <section><h2>오시는 길</h2><p>${v.address}</p><p>${v.tel}</p></section>
      <section><h2>마음 전하실 곳</h2><ul>${accs || '<li>축하의 마음만으로 충분합니다</li>'}</ul></section>
      <div class="gallery">${d.gallery.map(s => `<img src="${s}" alt="">`).join('')}</div>
    </main>`;
});
