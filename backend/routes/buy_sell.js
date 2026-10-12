const express = require('express');
const router = express.Router();
const pool = require('../db');

router.get('/', async (req, res) => {
  try {
    const { category } = req.query;
    let query = 'SELECT * FROM buy_sell_items WHERE status = $1';
    const params = ['active'];
    if (category && category !== 'All') {
      query += ' AND category = $2';
      params.push(category);
    }
    query += ' ORDER BY created_at DESC';
    const result = await pool.query(query, params);
    res.json({ success: true, items: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.get('/my-items/:sellerId', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM buy_sell_items WHERE seller_id = $1 ORDER BY created_at DESC', [req.params.sellerId]);
    res.json({ success: true, items: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/', async (req, res) => {
  const { itemName, price, priceType, description, imageUrl, sellerId, sellerName, sellerPhone, sellerApartment, category } = req.body;
  try {
    const result = await pool.query(
      'INSERT INTO buy_sell_items (item_name,price,price_type,description,image_url,seller_id,seller_name,seller_phone,seller_apartment,category) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *',
      [itemName, price, priceType, description, imageUrl, sellerId || null, sellerName, sellerPhone, sellerApartment, category]
    );
    res.json({ success: true, item: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.put('/:id', async (req, res) => {
  const { itemName, price, priceType, description, imageUrl, category } = req.body;
  try {
    const result = await pool.query(
      'UPDATE buy_sell_items SET item_name=$1,price=$2,price_type=$3,description=$4,image_url=$5,category=$6 WHERE id=$7 RETURNING *',
      [itemName, price, priceType, description, imageUrl, category, req.params.id]
    );
    res.json({ success: true, item: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.patch('/:id/sold', async (req, res) => {
  try {
    await pool.query('UPDATE buy_sell_items SET status=$1 WHERE id=$2', ['sold', req.params.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM buy_sell_items WHERE id=$1', [req.params.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
