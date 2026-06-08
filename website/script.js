// ── PRODUCTS DATA ──
const products = [
  { id: 1, name: 'Arctic Fox Fullsuit', category: 'fullsuit', emoji: '🦊', price: 1299, desc: 'White & blue arctic fox suit with poseable tail and handpaws.', badge: 'Popular' },
  { id: 2, name: 'Shadow Wolf Fullsuit', category: 'fullsuit', emoji: '🐺', price: 1199, desc: 'Dark grey wolf fullsuit with luminous amber eyes.', badge: null },
  { id: 3, name: 'Neon Leopard Suit', category: 'fullsuit', emoji: '🐆', price: 1349, desc: 'Vibrant neon spots on black base fur, UV-reactive accents.', badge: 'New' },
  { id: 4, name: 'Fox Partial Set', category: 'partial', emoji: '🦊', price: 449, desc: 'Includes head, handpaws, feetpaws, and fluffy tail.', badge: 'Popular' },
  { id: 5, name: 'Wolf Head + Paws', category: 'partial', emoji: '🐺', price: 399, desc: 'Realistic wolf head with moving jaw + matching paws.', badge: null },
  { id: 6, name: 'Bunny Partial', category: 'partial', emoji: '🐰', price: 359, desc: 'Soft pastel bunny with long floppy ears and button nose.', badge: 'Sale' },
  { id: 7, name: 'Dragon Cosplay', category: 'cosplay', emoji: '🐉', price: 899, desc: 'Majestic dragon costume with wing harness and scale texture.', badge: 'New' },
  { id: 8, name: 'Unicorn Cosplay', category: 'cosplay', emoji: '🦄', price: 799, desc: 'Rainbow unicorn full costume with light-up horn.', badge: null },
  { id: 9, name: 'Phoenix Cosplay', category: 'cosplay', emoji: '🔥', price: 949, desc: 'Fiery phoenix with feathered wings and ember-glow accents.', badge: 'Popular' },
  { id: 10, name: 'Fluffy Fox Tail', category: 'accessories', emoji: '🦊', price: 69, desc: 'Premium faux fur fox tail, belt-clip attachment.', badge: null },
  { id: 11, name: 'Wolf Ear Headband', category: 'accessories', emoji: '🐺', price: 39, desc: 'Realistic wolf ears on comfortable wire headband.', badge: 'Sale' },
  { id: 12, name: 'Paw Gloves Set', category: 'accessories', emoji: '🐾', price: 59, desc: 'Soft paw-print gloves in 8 color options.', badge: null },
];

let cart = [];
let currentFilter = 'all';

// ── RENDER PRODUCTS ──
function renderProducts(filter = 'all') {
  currentFilter = filter;
  const grid = document.getElementById('products-grid');
  const filtered = filter === 'all' ? products : products.filter(p => p.category === filter);

  grid.innerHTML = filtered.map(p => `
    <div class="product-card">
      <div class="product-img">
        <span>${p.emoji}</span>
        ${p.badge ? `<span class="product-badge">${p.badge}</span>` : ''}
      </div>
      <div class="product-info">
        <h3>${p.name}</h3>
        <p>${p.desc}</p>
        <div class="product-footer">
          <span class="price">$${p.price.toLocaleString()}</span>
          <button class="add-btn" onclick="addToCart(${p.id})">Add to Cart</button>
        </div>
      </div>
    </div>
  `).join('');
}

function filterProducts(filter) {
  renderProducts(filter);
  document.querySelectorAll('.filter-btn').forEach(btn => btn.classList.remove('active'));
  const btns = document.querySelectorAll('.filter-btn');
  const map = { all: 0, fullsuit: 1, partial: 2, cosplay: 3, accessories: 4 };
  if (map[filter] !== undefined) btns[map[filter]].classList.add('active');
  if (filter !== 'all') {
    document.getElementById('products').scrollIntoView({ behavior: 'smooth' });
  }
}

// ── CART ──
function addToCart(id) {
  const product = products.find(p => p.id === id);
  const existing = cart.find(i => i.id === id);
  if (existing) {
    existing.qty += 1;
  } else {
    cart.push({ ...product, qty: 1 });
  }
  updateCart();
  showToast(`${product.emoji} ${product.name} added to cart!`);
}

function removeFromCart(id) {
  cart = cart.filter(i => i.id !== id);
  updateCart();
}

function updateCart() {
  const count = cart.reduce((s, i) => s + i.qty, 0);
  document.getElementById('cart-count').textContent = count;

  const total = cart.reduce((s, i) => s + i.price * i.qty, 0);
  document.getElementById('cart-total').textContent = `$${total.toLocaleString('en-US', { minimumFractionDigits: 2 })}`;

  const itemsEl = document.getElementById('cart-items');
  if (cart.length === 0) {
    itemsEl.innerHTML = '<p class="empty-cart">Your cart is empty.</p>';
    return;
  }
  itemsEl.innerHTML = cart.map(i => `
    <div class="cart-item">
      <div style="font-size:2rem">${i.emoji}</div>
      <div class="cart-item-info" style="flex:1">
        <h4>${i.name}</h4>
        <p>Qty: ${i.qty} &times; $${i.price.toLocaleString()}</p>
      </div>
      <div class="cart-item-right">
        <span>$${(i.price * i.qty).toLocaleString()}</span>
        <button class="remove-btn" onclick="removeFromCart(${i.id})">✕</button>
      </div>
    </div>
  `).join('');
}

function toggleCart() {
  const panel = document.getElementById('cart-panel');
  const overlay = document.getElementById('cart-overlay');
  panel.classList.toggle('open');
  overlay.classList.toggle('open');
}

function checkout() {
  if (cart.length === 0) { showToast('Your cart is empty!'); return; }
  showToast('🎉 Order placed! Thank you for shopping at Fluffy Store!');
  cart = [];
  updateCart();
  toggleCart();
}

// ── MOBILE MENU ──
function toggleMenu() {
  document.querySelector('.nav-links').classList.toggle('mobile-open');
}

// ── CONTACT FORM ──
function submitForm(e) {
  e.preventDefault();
  showToast('🐾 Message sent! We\'ll get back to you soon.');
  e.target.reset();
}

// ── TOAST ──
function showToast(msg) {
  const toast = document.getElementById('toast');
  toast.textContent = msg;
  toast.classList.add('show');
  setTimeout(() => toast.classList.remove('show'), 3200);
}

// ── INIT ──
renderProducts();
