#!/usr/bin/env python3
"""
Test script for Smart Context Management System
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from mysql.connector import pooling
from smart_context import SmartContextManager

# Database config
db_config = {
    'host': 'localhost',
    'user': 'claude_user',
    'password': 'claudepass123',
    'database': 'claude_knowledge'
}

print("=" * 70)
print("SMART CONTEXT SYSTEM TEST")
print("=" * 70)

# Create connection pool
pool = pooling.MySQLConnectionPool(
    pool_name="test_pool",
    pool_size=2,
    **db_config
)

# Create manager
ctx = SmartContextManager(pool, lambda msg, level="INFO": print(f"[{level}] {msg}"))

# Test 1: User Preferences
print("\n--- TEST 1: User Preferences ---")
prefs = ctx.get_user_preferences('fotis')
if prefs:
    print(f"✓ Found user preferences for 'fotis'")
    print(f"  Language: {prefs.get('language')}")
    print(f"  Skill level: {prefs.get('skill_level')}")
    user_context = ctx.build_user_context('fotis')
    print(f"  User context length: {len(user_context)} chars")
else:
    print("✗ No user preferences found for 'fotis'")

# Test 2: Project Maps
print("\n--- TEST 2: Project Maps ---")
# Find a project with a map
conn = pool.get_connection()
cursor = conn.cursor(dictionary=True)
cursor.execute("SELECT id, name FROM projects WHERE id IN (SELECT project_id FROM project_maps) LIMIT 1")
project = cursor.fetchone()
cursor.close()
conn.close()

if project:
    proj_map = ctx.get_project_map(project['id'])
    if proj_map:
        print(f"✓ Found project map for '{project['name']}'")
        print(f"  File count: {proj_map.get('file_count')}")
        print(f"  Primary language: {proj_map.get('primary_language')}")
        print(f"  Tech stack: {proj_map.get('tech_stack')}")
else:
    print("✗ No projects with maps found")

# Test 3: Project Knowledge
print("\n--- TEST 3: Project Knowledge ---")
conn = pool.get_connection()
cursor = conn.cursor(dictionary=True)
cursor.execute("SELECT id, name FROM projects WHERE id IN (SELECT project_id FROM project_knowledge) LIMIT 1")
project_k = cursor.fetchone()
cursor.close()
conn.close()

if project_k:
    knowledge = ctx.get_project_knowledge(project_k['id'])
    if knowledge:
        print(f"✓ Found project knowledge for '{project_k['name']}'")
        print(f"  Has coding patterns: {bool(knowledge.get('coding_patterns'))}")
        print(f"  Has gotchas: {bool(knowledge.get('known_gotchas'))}")
else:
    print("✗ No projects with knowledge found")

# Test 4: Smart History
print("\n--- TEST 4: Smart History ---")
conn = pool.get_connection()
cursor = conn.cursor(dictionary=True)
cursor.execute("""
    SELECT t.id, t.ticket_number,
           (SELECT COUNT(*) FROM conversation_messages WHERE ticket_id = t.id) as msg_count
    FROM tickets t
    WHERE t.status != 'closed'
    ORDER BY msg_count DESC
    LIMIT 1
""")
ticket = cursor.fetchone()
cursor.close()
conn.close()

if ticket:
    print(f"Testing with ticket {ticket['ticket_number']} ({ticket['msg_count']} messages)")
    history = ctx.get_smart_history(ticket['id'])
    print(f"✓ Got smart history: {len(history)} messages")
    total_tokens = sum(ctx.count_tokens(m.get('content', '')) for m in history)
    print(f"  Total tokens in history: {total_tokens}")
else:
    print("✗ No tickets found")

# Test 5: Extraction
print("\n--- TEST 5: Extraction ---")
if ticket and ticket['msg_count'] > 5:
    # Get first 5 messages to extract
    conn = pool.get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT id, role, content, token_count
        FROM conversation_messages
        WHERE ticket_id = %s AND is_summarized = FALSE
        ORDER BY id
        LIMIT 5
    """, (ticket['id'],))
    messages = cursor.fetchall()
    cursor.close()
    conn.close()

    if messages:
        print(f"Extracting {len(messages)} messages...")
        extraction = ctx.create_extraction(ticket['id'], messages)
        if extraction:
            print(f"✓ Extraction created successfully")
            print(f"  Tokens before: {extraction.get('tokens_before')}")
            print(f"  Tokens after: {extraction.get('tokens_after')}")
            print(f"  Messages summarized: {extraction.get('messages_summarized')}")
            print(f"  Decisions found: {extraction.get('decisions')}")
            print(f"  Files detected: {extraction.get('files_modified')}")
        else:
            print("✗ Extraction failed")
    else:
        print("✗ No messages to extract")
else:
    print("✗ Not enough messages to test extraction")

# Test 6: Full Context Build
print("\n--- TEST 6: Full Context Build ---")
if ticket:
    # Get full ticket info
    conn = pool.get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT t.*, p.web_path, p.app_path, p.name as project_name
        FROM tickets t
        JOIN projects p ON t.project_id = p.id
        WHERE t.id = %s
    """, (ticket['id'],))
    full_ticket = cursor.fetchone()
    cursor.close()
    conn.close()

    if full_ticket:
        result = ctx.build_full_context(full_ticket, user_id='fotis')
        print(f"✓ Built full context")
        system_ctx = result.get('system_context', '')
        history = result.get('history', [])
        print(f"  System context length: {len(system_ctx)} chars (~{len(system_ctx)//4} tokens)")
        print(f"  History messages: {len(history)}")
        print(f"  Contains user prefs: {'USER PREFERENCES' in system_ctx}")
        print(f"  Contains project map: {'PROJECT STRUCTURE' in system_ctx}")
        print(f"  Contains project knowledge: {'PROJECT KNOWLEDGE' in system_ctx}")
        print(f"  Contains extraction: {'PREVIOUS CONTEXT' in system_ctx or 'extraction' in system_ctx.lower()}")
        if system_ctx:
            print(f"\nContext preview (first 800 chars):\n{system_ctx[:800]}")
    else:
        print("✗ Could not get full ticket info")

# Test 7: Views
print("\n--- TEST 7: Database Views ---")
conn = pool.get_connection()
cursor = conn.cursor(dictionary=True)

cursor.execute("SELECT COUNT(*) as cnt FROM v_ticket_context")
result = cursor.fetchone()
print(f"✓ v_ticket_context: {result['cnt']} rows")

cursor.execute("SELECT COUNT(*) as cnt FROM v_tickets_needing_extraction")
result = cursor.fetchone()
print(f"✓ v_tickets_needing_extraction: {result['cnt']} tickets need extraction")

cursor.execute("SELECT COUNT(*) as cnt FROM v_projects_needing_map")
result = cursor.fetchone()
print(f"✓ v_projects_needing_map: {result['cnt']} projects need maps")

cursor.close()
conn.close()

print("\n" + "=" * 70)
print("TEST COMPLETE")
print("=" * 70)
