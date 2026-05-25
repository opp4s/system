--
-- PostgreSQL database dump
--

\restrict AvE9Zhuel4qd4HE0UVneyfibDoSsQ8ygcHhL1fWmi5Rz5WYlAxywobLB8X4VnUN

-- Dumped from database version 16.14 (Debian 16.14-1.pgdg12+1)
-- Dumped by pg_dump version 16.14 (Debian 16.14-1.pgdg12+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: contact_inboxes; Type: TABLE DATA; Schema: public; Owner: opp4s
--

COPY public.contact_inboxes (id, contact_id, inbox_id, source_id, created_at, updated_at, hmac_verified, pubsub_token) FROM stdin;
\.


--
-- Data for Name: contacts; Type: TABLE DATA; Schema: public; Owner: opp4s
--

COPY public.contacts (id, name, email, phone_number, account_id, created_at, updated_at, additional_attributes, identifier, custom_attributes, last_activity_at, contact_type, middle_name, last_name, location, country_code, blocked, company_id) FROM stdin;
1	EvolutionAPI	\N	+123456	1	2026-05-22 20:37:58.540669	2026-05-22 20:49:58.981572	{"avatar_url_hash": "245e493457bbe42981ae8bafe6c05adaa8dedbf5c5fa20ab2b9e807d1f5ada57", "last_avatar_sync_at": "2026-05-22T20:38:30Z"}	\N	{}	2026-05-22 20:49:58.966022	1			\N	\N	f	\N
2	Smoke P4	smoke-p4@test.com	\N	1	2026-05-24 18:22:38.365897	2026-05-24 18:22:38.365897	{"avatar_url_hash": "2ab3f752fef0aa350507cfeff6c4e96780c5496b6d4519a96dcef5d6b18e388e", "last_avatar_sync_at": "2026-05-24T18:23:14Z"}	\N	{}	\N	1			\N	\N	f	\N
3	Cliente Teste	\N	+5511888888888	1	2026-05-24 18:41:31.592206	2026-05-24 18:41:31.592206	{}	\N	{}	\N	1			\N	\N	f	\N
4	Smoke P5	\N	+5511777000001	1	2026-05-24 18:50:14.741663	2026-05-24 18:50:14.741663	{}	\N	{}	\N	1			\N	\N	f	\N
5	Foto Test	\N	+5511777777777	1	2026-05-24 18:54:37.614306	2026-05-24 18:54:37.614306	{}	\N	{}	\N	1			\N	\N	f	\N
6	Foto Test 2	\N	+5511666666666	1	2026-05-24 19:02:11.396032	2026-05-24 19:02:11.396032	{}	\N	{}	\N	1			\N	\N	f	\N
7	Foto Test 3	\N	+5511555555555	1	2026-05-24 19:04:26.346309	2026-05-24 19:04:26.346309	{}	\N	{}	\N	1			\N	\N	f	\N
8	Smoke P6	\N	+5511444000001	1	2026-05-24 19:08:31.219801	2026-05-24 19:08:31.219801	{}	\N	{}	\N	1			\N	\N	f	\N
9	Self Test	\N	+5541999953255	1	2026-05-24 19:25:16.147235	2026-05-24 19:25:16.147235	{}	\N	{}	\N	1			\N	\N	f	\N
10	Guard Test	\N	+5511000099999	1	2026-05-24 19:30:20.216981	2026-05-24 19:30:20.216981	{}	\N	{}	\N	1			\N	\N	f	\N
11	Mello	\N	+554199953255	1	2026-05-25 00:03:40.058203	2026-05-25 00:03:40.058203	{}	\N	{}	\N	1			\N	\N	f	\N
\.


--
-- Data for Name: conversations; Type: TABLE DATA; Schema: public; Owner: opp4s
--

COPY public.conversations (id, account_id, inbox_id, status, assignee_id, created_at, updated_at, contact_id, display_id, contact_last_seen_at, agent_last_seen_at, additional_attributes, contact_inbox_id, uuid, identifier, last_activity_at, team_id, campaign_id, snoozed_until, custom_attributes, assignee_last_seen_at, first_reply_created_at, priority, sla_policy_id, waiting_since, cached_label_list, assignee_agent_bot_id) FROM stdin;
\.


--
-- Data for Name: inboxes; Type: TABLE DATA; Schema: public; Owner: opp4s
--

COPY public.inboxes (id, channel_id, account_id, name, created_at, updated_at, channel_type, enable_auto_assignment, greeting_enabled, greeting_message, email_address, working_hours_enabled, out_of_office_message, timezone, enable_email_collect, csat_survey_enabled, allow_messages_after_resolved, auto_assignment_config, lock_to_single_conversation, portal_id, sender_name_type, business_name, csat_config) FROM stdin;
25	25	1	WhatsApp +5541995017777	2026-05-25 03:37:09.297672	2026-05-25 03:37:09.297672	Channel::Api	t	f	\N	\N	f	\N	UTC	t	f	t	{}	f	\N	0	\N	{}
\.


--
-- Data for Name: whatsapp_lite_channels; Type: TABLE DATA; Schema: public; Owner: opp4s
--

COPY public.whatsapp_lite_channels (id, account_id, inbox_id, instance_id, phone_number, status, qr_expires_at, created_at, updated_at, deleted_at) FROM stdin;
37	1	25	cw-1-5541995017777	+5541995017777	2	2026-05-25 03:38:00	2026-05-25 03:37:09.407054	2026-05-25 03:37:24.972221	\N
\.


--
-- Name: contact_inboxes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: opp4s
--

SELECT pg_catalog.setval('public.contact_inboxes_id_seq', 14, true);


--
-- Name: contacts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: opp4s
--

SELECT pg_catalog.setval('public.contacts_id_seq', 11, true);


--
-- Name: conversations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: opp4s
--

SELECT pg_catalog.setval('public.conversations_id_seq', 14, true);


--
-- Name: inboxes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: opp4s
--

SELECT pg_catalog.setval('public.inboxes_id_seq', 35, true);


--
-- Name: whatsapp_lite_channels_id_seq; Type: SEQUENCE SET; Schema: public; Owner: opp4s
--

SELECT pg_catalog.setval('public.whatsapp_lite_channels_id_seq', 47, true);


--
-- PostgreSQL database dump complete
--

\unrestrict AvE9Zhuel4qd4HE0UVneyfibDoSsQ8ygcHhL1fWmi5Rz5WYlAxywobLB8X4VnUN

