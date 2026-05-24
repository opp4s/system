--
-- PostgreSQL database dump
--

\restrict g0wzbAJwEIuZ9e9liaWwyh4vauDQzmEfMgKevp0El6e1KoexocUMq4IVpU5mLD3

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
\.


--
-- Data for Name: contacts; Type: TABLE DATA; Schema: public; Owner: opp4s
--

COPY public.contacts (id, name, email, phone_number, account_id, created_at, updated_at, additional_attributes, identifier, custom_attributes, last_activity_at, contact_type, middle_name, last_name, location, country_code, blocked, company_id) FROM stdin;
1	EvolutionAPI	\N	+123456	1	2026-05-22 20:37:58.540669	2026-05-22 20:49:58.981572	{"avatar_url_hash": "245e493457bbe42981ae8bafe6c05adaa8dedbf5c5fa20ab2b9e807d1f5ada57", "last_avatar_sync_at": "2026-05-22T20:38:30Z"}	\N	{}	2026-05-22 20:49:58.966022	1			\N	\N	f	\N
2	Smoke P4	smoke-p4@test.com	\N	1	2026-05-24 18:22:38.365897	2026-05-24 18:22:38.365897	{"avatar_url_hash": "2ab3f752fef0aa350507cfeff6c4e96780c5496b6d4519a96dcef5d6b18e388e", "last_avatar_sync_at": "2026-05-24T18:23:14Z"}	\N	{}	\N	1			\N	\N	f	\N
3	Cliente Teste	\N	+5511888888888	1	2026-05-24 18:41:31.592206	2026-05-24 18:41:31.592206	{}	\N	{}	\N	1			\N	\N	f	\N
4	Smoke P5	\N	+5511777000001	1	2026-05-24 18:50:14.741663	2026-05-24 18:50:14.741663	{}	\N	{}	\N	1			\N	\N	f	\N
\.


--
-- Data for Name: conversations; Type: TABLE DATA; Schema: public; Owner: opp4s
--

COPY public.conversations (id, account_id, inbox_id, status, assignee_id, created_at, updated_at, contact_id, display_id, contact_last_seen_at, agent_last_seen_at, additional_attributes, contact_inbox_id, uuid, identifier, last_activity_at, team_id, campaign_id, snoozed_until, custom_attributes, assignee_last_seen_at, first_reply_created_at, priority, sla_policy_id, waiting_since, cached_label_list, assignee_agent_bot_id) FROM stdin;
1	1	1	0	\N	2026-05-22 20:37:59.508862	2026-05-22 20:40:11.990302	1	1	\N	\N	{}	2	7f3a2920-910b-446e-9c6e-ec38ef0460cc	\N	2026-05-22 20:40:11.9862	\N	\N	\N	{}	\N	2026-05-22 20:38:00.437205	\N	\N	2026-05-22 20:38:11.035104	\N	\N
2	1	1	0	\N	2026-05-22 20:40:53.967323	2026-05-22 20:49:58.903241	1	2	\N	\N	{}	3	6bb07f87-b5d1-41ec-b635-43e789bc2d4b	\N	2026-05-22 20:49:58.890742	\N	\N	\N	{}	\N	2026-05-22 20:40:54.343409	\N	\N	2026-05-22 20:40:55.826608	\N	\N
4	1	3	0	\N	2026-05-24 18:41:31.782254	2026-05-24 18:41:32.063286	3	4	\N	\N	{"source": "whatsapp_lite"}	5	aaee3330-0c71-44fb-b83c-f2d30d9dac2e	\N	2026-05-24 18:41:32.052871	\N	\N	\N	{}	\N	\N	\N	\N	2026-05-24 18:41:31.782254	\N	\N
3	1	2	0	\N	2026-05-24 18:24:22.979294	2026-05-24 18:49:46.576161	2	3	\N	\N	{}	4	af4b6dab-a45c-42d4-83bd-45b50c9b6196	\N	2026-05-24 18:49:46.553564	\N	\N	\N	{}	\N	\N	\N	\N	2026-05-24 18:24:22.979294	\N	\N
5	1	3	0	\N	2026-05-24 18:50:14.818621	2026-05-24 18:50:14.93318	4	5	\N	\N	{"source": "whatsapp_lite"}	6	8d540a33-50f3-4922-b0db-eb028c8cb4cc	\N	2026-05-24 18:50:14.928139	\N	\N	\N	{}	\N	\N	\N	\N	2026-05-24 18:50:14.818621	\N	\N
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

SELECT pg_catalog.setval('public.contact_inboxes_id_seq', 6, true);


--
-- Name: contacts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: opp4s
--

SELECT pg_catalog.setval('public.contacts_id_seq', 4, true);


--
-- Name: conversations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: opp4s
--

SELECT pg_catalog.setval('public.conversations_id_seq', 5, true);


--
-- Name: inboxes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: opp4s
--

SELECT pg_catalog.setval('public.inboxes_id_seq', 3, true);


--
-- Name: whatsapp_lite_channels_id_seq; Type: SEQUENCE SET; Schema: public; Owner: opp4s
--

SELECT pg_catalog.setval('public.whatsapp_lite_channels_id_seq', 8, true);


--
-- PostgreSQL database dump complete
--

\unrestrict g0wzbAJwEIuZ9e9liaWwyh4vauDQzmEfMgKevp0El6e1KoexocUMq4IVpU5mLD3

