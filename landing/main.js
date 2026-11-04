(() => {
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const header = document.querySelector('[data-header]');
  const menuButton = document.querySelector('.menu-btn');
  const mobileNav = document.getElementById('mobileNav');
  const year = document.getElementById('year');

  if (year) year.textContent = new Date().getFullYear();

  /* Header background */
  const onScroll = () => {
    if (!header) return;
    header.classList.toggle('is-scrolled', window.scrollY > 24);
  };
  onScroll();
  window.addEventListener('scroll', onScroll, { passive: true });

  /* Mobile menu */
  const setMenu = (open) => {
    document.body.classList.toggle('nav-open', open);
    if (menuButton) menuButton.setAttribute('aria-expanded', String(open));
    if (mobileNav) mobileNav.setAttribute('aria-hidden', String(!open));
  };

  if (menuButton) {
    menuButton.addEventListener('click', () => {
      setMenu(!document.body.classList.contains('nav-open'));
    });
  }
  if (mobileNav) {
    mobileNav.querySelectorAll('a').forEach((link) => {
      link.addEventListener('click', () => setMenu(false));
    });
  }
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') setMenu(false);
  });
  window.addEventListener('resize', () => {
    if (window.innerWidth > 980) setMenu(false);
  }, { passive: true });

  /* Scroll reveals */
  const revealItems = Array.from(document.querySelectorAll('.reveal'));
  revealItems.forEach((el) => {
    const delay = el.dataset.delay;
    if (delay) el.style.transitionDelay = `${delay}ms`;
  });

  if (reduceMotion || !('IntersectionObserver' in window)) {
    revealItems.forEach((el) => el.classList.add('in'));
  } else {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('in');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -6% 0px' });
    revealItems.forEach((el) => observer.observe(el));
  }

  /* Some embedded/headless webviews throttle IntersectionObserver. Make sure
     content above the fold is never left invisible. */
  const revealInView = () => {
    if (reduceMotion) return;
    revealItems.forEach((el) => {
      if (el.classList.contains('in')) return;
      const rect = el.getBoundingClientRect();
      if (rect.top < window.innerHeight * 0.94 && rect.bottom > 0) {
        el.classList.add('in');
      }
    });
  };
  window.setTimeout(revealInView, 900);
  window.addEventListener('scroll', () => window.requestAnimationFrame(revealInView), { passive: true });
  window.addEventListener('resize', revealInView, { passive: true });

  /* Screenshot switcher */
  const shots = {
    home: { src: 'assets/shots/home-desktop.jpg', path: 'discover', alt: 'MuseFlow 桌面端发现页' },
    player: { src: 'assets/shots/player-desktop.jpg', path: 'now-playing', alt: 'MuseFlow 桌面端播放器' },
    search: { src: 'assets/shots/search-desktop.jpg', path: 'search', alt: 'MuseFlow 桌面端搜索页' },
    library: { src: 'assets/shots/library-desktop.jpg', path: 'library', alt: 'MuseFlow 桌面端音乐库' }
  };
  const tabs = Array.from(document.querySelectorAll('.shot-tab'));
  const shotImage = document.getElementById('desktopShot');
  const shotPath = document.getElementById('shotPath');

  const preload = () => Object.values(shots).forEach((shot) => {
    const image = new Image();
    image.src = shot.src;
  });

  const selectShot = (key) => {
    const shot = shots[key];
    if (!shot || !shotImage) return;
    tabs.forEach((tab) => {
      const active = tab.dataset.shot === key;
      tab.classList.toggle('is-active', active);
      tab.setAttribute('aria-selected', String(active));
    });
    shotImage.classList.add('is-swapping');
    window.setTimeout(() => {
      shotImage.src = shot.src;
      shotImage.alt = shot.alt;
      if (shotPath) shotPath.textContent = shot.path;
      shotImage.classList.remove('is-swapping');
    }, reduceMotion ? 0 : 140);
  };

  tabs.forEach((tab) => {
    tab.addEventListener('click', () => selectShot(tab.dataset.shot));
  });
  if ('requestIdleCallback' in window) requestIdleCallback(preload);
  else window.addEventListener('load', preload, { once: true });

  /* Subtle hero parallax */
  const auras = Array.from(document.querySelectorAll('[data-parallax]'));
  if (auras.length && !reduceMotion && window.matchMedia('(pointer: fine)').matches) {
    let raf = 0;
    let targetX = 0;
    let targetY = 0;
    window.addEventListener('pointermove', (event) => {
      targetX = (event.clientX / window.innerWidth - 0.5) * 2;
      targetY = (event.clientY / window.innerHeight - 0.5) * 2;
      if (!raf) {
        raf = requestAnimationFrame(() => {
          auras.forEach((aura) => {
            const strength = Number(aura.dataset.parallax) * 100;
            aura.style.transform = `translate3d(${targetX * strength}px, ${targetY * strength}px, 0)`;
          });
          raf = 0;
        });
      }
    }, { passive: true });
  }

  /* Closing the mobile menu on hash navigation */
  window.addEventListener('hashchange', () => setMenu(false));
})();
