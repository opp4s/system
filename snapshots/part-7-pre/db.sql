--
-- PostgreSQL database dump
--

\restrict W0DwQ3Zm7rBaIu4iPgdmd2u2QK1QUcr4oTh0lLRefbKvXeKXgGHw8a3cY0rkD5W

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
1	1	1	933b5e15-a7ce-4b86-80eb-cb6fdc2f0145	2026-05-22 20:37:58.736177	2026-05-22 20:37:58.736177	f	P3BWRtPiKpQx7ewvPnAhgMUg
2	1	1	16617f9a-dab5-48e2-9324-48ddb81319b8	2026-05-22 20:37:59.338187	2026-05-22 20:37:59.338187	f	feJ4DSuBDhRN88KKJeVHz9MC
3	1	1	c62daac2-071c-454c-8af2-aa9bc51d4753	2026-05-22 20:40:53.943376	2026-05-22 20:40:53.943376	f	D512TY2fuuVCVCeb8tnCb3mR
4	2	2	acb83b4e-b837-40e6-97a2-6b3432e4e52f	2026-05-24 18:24:22.884077	2026-05-24 18:24:22.884077	f	gc1KajhmbqX8uKH6sxi9yDQP
5	3	3	73f4c4ad-b979-4097-86ec-b4fa0a73c380	2026-05-24 18:41:31.685143	2026-05-24 18:41:31.685143	f	qLaNLshNTQXfRF5AHbra6JxD
6	4	3	2dfa5af3-cb63-4e7e-a450-0da0b7c13aca	2026-05-24 18:50:14.798695	2026-05-24 18:50:14.798695	f	DyWUk7pUEpn6WtqA2YChDaWs
7	5	3	4edb94e0-074f-4828-9551-e05bff0976eb	2026-05-24 18:54:37.69176	2026-05-24 18:54:37.69176	f	LmCbK15NS4KmFGWAjyhgvorc
8	6	3	b3a8b30a-7e31-407a-a525-684574c4fca1	2026-05-24 19:02:11.504662	2026-05-24 19:02:11.504662	f	D8Y21oaHxquKC9aU2PyTvSxj
9	7	3	c2ae8566-61fe-4d26-8fca-801ff8cf14f9	2026-05-24 19:04:26.388497	2026-05-24 19:04:26.388497	f	1zETiw7AYz8zr8dXpfyA1Vc7
10	8	3	598d8196-5cba-420b-a55c-844c3dde129e	2026-05-24 19:08:31.255226	2026-05-24 19:08:31.255226	f	yJkp9yrdyQh4QrvQWa6bHfWF
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
\.


--
-- Data for Name: conversations; Type: TABLE DATA; Schema: public; Owner: opp4s
--

COPY public.conversations (id, account_id, inbox_id, status, assignee_id, created_at, updated_at, contact_id, display_id, contact_last_seen_at, agent_last_seen_at, additional_attributes, contact_inbox_id, uuid, identifier, last_activity_at, team_id, campaign_id, snoozed_until, custom_attributes, assignee_last_seen_at, first_reply_created_at, priority, sla_policy_id, waiting_since, cached_label_list, assignee_agent_bot_id) FROM stdin;
3	1	2	0	\N	2026-05-24 18:24:22.979294	2026-05-24 19:13:37.659992	2	3	\N	\N	{}	4	af4b6dab-a45c-42d4-83bd-45b50c9b6196	\N	2026-05-24 19:13:37.629795	\N	\N	\N	{}	\N	\N	\N	\N	2026-05-24 18:24:22.979294	\N	\N
5	1	3	0	\N	2026-05-24 18:50:14.818621	2026-05-24 19:14:04.62581	4	5	\N	\N	{"source": "whatsapp_lite"}	6	8d540a33-50f3-4922-b0db-eb028c8cb4cc	\N	2026-05-24 19:14:04.615833	\N	\N	\N	{}	\N	\N	\N	\N	2026-05-24 18:50:14.818621	\N	\N
9	1	3	0	\N	2026-05-24 19:08:31.28354	2026-05-24 19:14:55.154179	8	9	\N	\N	{"source": "whatsapp_lite"}	10	14668b33-dbc5-4a11-9547-cb1c0afe69aa	\N	2026-05-24 19:14:55.141579	\N	\N	\N	{}	\N	\N	\N	\N	2026-05-24 19:08:31.28354	\N	\N
1	1	1	0	\N	2026-05-22 20:37:59.508862	2026-05-22 20:40:11.990302	1	1	\N	\N	{}	2	7f3a2920-910b-446e-9c6e-ec38ef0460cc	\N	2026-05-22 20:40:11.9862	\N	\N	\N	{}	\N	2026-05-22 20:38:00.437205	\N	\N	2026-05-22 20:38:11.035104	\N	\N
2	1	1	0	\N	2026-05-22 20:40:53.967323	2026-05-22 20:49:58.903241	1	2	\N	\N	{}	3	6bb07f87-b5d1-41ec-b635-43e789bc2d4b	\N	2026-05-22 20:49:58.890742	\N	\N	\N	{}	\N	2026-05-22 20:40:54.343409	\N	\N	2026-05-22 20:40:55.826608	\N	\N
4	1	3	0	\N	2026-05-24 18:41:31.782254	2026-05-24 18:41:32.063286	3	4	\N	\N	{"source": "whatsapp_lite"}	5	aaee3330-0c71-44fb-b83c-f2d30d9dac2e	\N	2026-05-24 18:41:32.052871	\N	\N	\N	{}	\N	\N	\N	\N	2026-05-24 18:41:31.782254	\N	\N
6	1	3	0	\N	2026-05-24 18:54:37.755678	2026-05-24 18:54:38.00954	5	6	\N	\N	{"source": "whatsapp_lite"}	7	77b71a28-1f5b-4824-9881-7a8179748648	\N	2026-05-24 18:54:38.004661	\N	\N	\N	{}	\N	\N	\N	\N	2026-05-24 18:54:37.755678	\N	\N
7	1	3	0	\N	2026-05-24 19:02:11.600302	2026-05-24 19:02:11.998614	6	7	\N	\N	{"source": "whatsapp_lite"}	8	61ca7c64-28a3-49c1-97b1-c5b3b676f08d	\N	2026-05-24 19:02:11.991287	\N	\N	\N	{}	\N	\N	\N	\N	2026-05-24 19:02:11.600302	\N	\N
8	1	3	0	\N	2026-05-24 19:04:26.419567	2026-05-24 19:04:26.515748	7	8	\N	\N	{"source": "whatsapp_lite"}	9	b4e13272-2bbb-4cd3-9fd1-bc36a2141601	\N	2026-05-24 19:04:26.507884	\N	\N	\N	{}	\N	\N	\N	\N	2026-05-24 19:04:26.419567	\N	\N
\.


--
-- Data for Name: inboxes; Type: TABLE DATA; Schema: public; Owner: opp4s
--

COPY public.inboxes (id, channel_id, account_id, name, created_at, updated_at, channel_type, enable_auto_assignment, greeting_enabled, greeting_message, email_address, working_hours_enabled, out_of_office_message, timezone, enable_email_collect, csat_survey_enabled, allow_messages_after_resolved, auto_assignment_config, lock_to_single_conversation, portal_id, sender_name_type, business_name, csat_config) FROM stdin;
1	1	1	41999990004	2026-05-22 20:37:57.920897	2026-05-22 20:37:57.920897	Channel::Api	t	f	\N	\N	f	\N	UTC	t	f	t	{}	f	\N	0	\N	{}
2	2	1	WA Lite Smoke P4	2026-05-24 18:22:37.890684	2026-05-24 18:22:37.890684	Channel::Api	t	f	\N	\N	f	\N	UTC	t	f	t	{}	f	\N	0	\N	{}
3	3	1	WhatsApp Lite Test	2026-05-24 18:39:56.671933	2026-05-24 18:39:56.671933	Channel::Api	t	f	\N	\N	f	\N	UTC	t	f	t	{}	f	\N	0	\N	{}
\.


--
-- Data for Name: whatsapp_lite_channels; Type: TABLE DATA; Schema: public; Owner: opp4s
--

COPY public.whatsapp_lite_channels (id, account_id, inbox_id, instance_id, phone_number, status, qr_expires_at, created_at, updated_at) FROM stdin;
4	1	2	cw-1-smoke-p4	+5511900000001	0	\N	2026-05-24 18:22:38.234625	2026-05-24 18:22:38.234625
7	1	3	cw-1-5511999999999	+5511999999999	2	\N	2026-05-24 18:39:56.833508	2026-05-24 18:41:02.687697
\.


--
-- Name: contact_inboxes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: opp4s
--

SELECT pg_catalog.setval('public.contact_inboxes_id_seq', 10, true);


--
-- Name: contacts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: opp4s
--

SELECT pg_catalog.setval('public.contacts_id_seq', 8, true);


--
-- Name: conversations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: opp4s
--

SELECT pg_catalog.setval('public.conversations_id_seq', 9, true);


--
-- Name: inboxes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: opp4s
--

SELECT pg_catalog.setval('public.inboxes_id_seq', 3, true);


--
-- Name: whatsapp_lite_channels_id_seq; Type: SEQUENCE SET; Schema: public; Owner: opp4s
--

SELECT pg_catalog.setval('public.whatsapp_lite_channels_id_seq', 11, true);


--
-- PostgreSQL database dump complete
--

\unrestrict W0DwQ3Zm7rBaIu4iPgdmd2u2QK1QUcr4oTh0lLRefbKvXeKXgGHw8a3cY0rkD5W

