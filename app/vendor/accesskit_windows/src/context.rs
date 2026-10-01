// Copyright 2023 The AccessKit Authors. All rights reserved.
// Licensed under the Apache License, Version 2.0 (found in
// the LICENSE-APACHE file) or the MIT license (found in
// the LICENSE-MIT file), at your option.

use accesskit::{ActionHandler, ActionRequest, Point};
use accesskit_consumer::{NodeId, Tree};
use hashbrown::HashMap;
use std::fmt::{Debug, Formatter};
use std::sync::{Arc, Mutex, RwLock, RwLockReadGuard, atomic::AtomicBool};
use windows::core::ComObject;

use crate::{node::PlatformNode, util::*, window_handle::WindowHandle};

pub(crate) trait ActionHandlerNoMut {
    fn do_action(&self, request: ActionRequest);
}

pub(crate) struct ActionHandlerWrapper<H: ActionHandler + Send>(Mutex<H>);

impl<H: 'static + ActionHandler + Send> ActionHandlerWrapper<H> {
    pub(crate) fn new(inner: H) -> Self {
        Self(Mutex::new(inner))
    }
}

impl<H: ActionHandler + Send> ActionHandlerNoMut for ActionHandlerWrapper<H> {
    fn do_action(&self, request: ActionRequest) {
        self.0.lock().unwrap().do_action(request)
    }
}

pub(crate) struct Context {
    pub(crate) hwnd: WindowHandle,
    pub(crate) tree: RwLock<Tree>,
    pub(crate) action_handler: Arc<dyn ActionHandlerNoMut + Send + Sync>,
    pub(crate) is_placeholder: AtomicBool,
    platform_nodes: Mutex<HashMap<NodeId, ComObject<PlatformNode>>>,
}

impl Debug for Context {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Context")
            .field("hwnd", &self.hwnd)
            .field("tree", &self.tree)
            .field("action_handler", &"ActionHandler")
            .field("is_placeholder", &self.is_placeholder)
            .finish()
    }
}

impl Context {
    pub(crate) fn new(
        hwnd: WindowHandle,
        tree: Tree,
        action_handler: Arc<dyn ActionHandlerNoMut + Send + Sync>,
        is_placeholder: bool,
    ) -> Arc<Self> {
        Arc::new(Self {
            hwnd,
            tree: RwLock::new(tree),
            action_handler,
            is_placeholder: AtomicBool::new(is_placeholder),
            platform_nodes: Mutex::new(HashMap::new()),
        })
    }

    pub(crate) fn read_tree(&self) -> RwLockReadGuard<'_, Tree> {
        self.tree.read().unwrap()
    }

    pub(crate) fn client_top_left(&self) -> Point {
        client_top_left(self.hwnd)
    }

    pub(crate) fn do_action(&self, request: ActionRequest) {
        self.action_handler.do_action(request);
    }

    pub(crate) fn get_or_create_platform_node(
        self: &Arc<Self>,
        id: NodeId,
    ) -> ComObject<PlatformNode> {
        let mut platform_nodes = self.platform_nodes.lock().unwrap();
        if let Some(result) = platform_nodes.get(&id) {
            return result.clone();
        }

        let result = PlatformNode::new(self, id);
        platform_nodes.insert(id, result.clone());
        result
    }

    pub(crate) fn remove_platform_node(&self, id: NodeId) {
        let mut platform_nodes = self.platform_nodes.lock().unwrap();
        platform_nodes.remove(&id);
    }
}
