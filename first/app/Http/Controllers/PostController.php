<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;

class PostController extends Controller
{
    public function index(){
    	$posts = Post::latest()->get();
    	return response()->json($posts);
    }
    
    public function store(Request $request){
    	$validatedData = $request->validate([
    		'title' 	=> 'required|string|max:255',
    		'content'	=> 'required|string',
    	]);
    	
    	$post = Post::create($validatedData);
    	
    	return response()->json($post, 201);
    }
    
    public function show(Post $post){
    	return response()->json($post);
    }
    
    public function update(Request $request, Post $post){
    	$validatedData = $request->validate([
    		'title'		=> 'required|string|max:255',
    		'content'	=> 'required|string',
    	]);
    	
    	$post->update($validatedData);
    	
    	return response()->json($post);
    }
    
    public function destory(Post $post){
    	$post->delete();
    	
    	return response()->json(null, 204);
    }
}
